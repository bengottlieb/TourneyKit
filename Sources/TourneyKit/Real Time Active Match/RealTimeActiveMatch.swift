//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

public protocol SomeMatch: AnyObject { }


public class RealTimeActiveMatch<Delegate: RealTimeActiveMatchDelegate>: NSObject, ObservableObject, GKMatchDelegate, SomeMatch {
	public let match: GKMatch
	public var delegate: Delegate?
	public private(set) var phase: ActiveMatchPhase = .loading
	@Published public var recentlyReceivedData: [MatchMessage] = []
	var recentDataDepth = 5
	@Published public var recentErrors: [Error] = []
	public var allPlayers: [GKPlayer] { [GKLocalPlayer.local] + match.players }
	
	init(match: GKMatch, delegate: Delegate?) {
		self.match = match
		super.init()
		
		self.delegate = delegate
		match.delegate = self
	}
	
	public func startMatch() {
		self.phase = .playing
		sendPhaseChangedMessage()
	}
	
	func sendPlayerInfo(for player: GKPlayer = GKLocalPlayer.local) {
		try? send(message: MessagePlayerInfo(player), reliably: true)
	}
	
	func sendPhaseChangedMessage() {
		try? send(message: MessageMatchPhaseChange(phase))
	}
	
	func terminateLocally() {
		Task {
			await MainActor.run {
				if MatchManager.instance.realTimeActiveMatch === self {
					MatchManager.instance.realTimeActiveMatch = nil
				}
			}
		}
		match.disconnect()
	}
	
	public func endMatch() {
		phase = .ended
		sendPhaseChangedMessage()
	}
	
	public func terminate() {
		terminateLocally()
	}
	
	func send(data: Data, reliably: Bool = true) throws {
//		print("Sending: \(String(data: data, encoding: .utf8) ?? "something")")
		try match.sendData(toAllPlayers: data, with: reliably ? .reliable : .unreliable)
	}

	public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
		Logger.instance.log(.matchChangedPlayerState(match, player, state))
		if state == .connected { sendPlayerInfo() }
		Task {
			await MainActor.run {
				self.delegate?.playersChanged(to: allPlayers)
			}
		}
	}
	
	public func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
		Logger.instance.log(.matchShouldReinviteDisconnectedPlayer(match, player))
		 return true
	}

	public func match(_ match: GKMatch, didReceive data: Data, forRecipient recipient: GKPlayer, fromRemotePlayer player: GKPlayer) {
		Logger.instance.log(.matchReceivedData(match, player, data))
		handleIncoming(data: data, from: player)
	}
	
	func handleRemotePhaseChange(to newPhase: ActiveMatchPhase) {
		if self.phase == newPhase { return }
		self.phase = newPhase
		
		Task {
			await MainActor.run { delegate?.matchPhaseChanged(to: newPhase, in: self) }
		}
	}
}

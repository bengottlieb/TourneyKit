//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

public class RealTimeActiveMatch<Game: RealTimeGame>: NSObject, ObservableObject, GKMatchDelegate, SomeMatch {
	public let match: GKMatch
	public var game: Game?
	public private(set) var phase: ActiveMatchPhase = .loading
	@Published public var recentlyReceivedData: [MatchMessage] = []
	var recentDataDepth = 5
	@Published public var recentErrors: [Error] = []
	public var allPlayers: [GKPlayer] { [GKLocalPlayer.local] + match.players }
	public var parentGame: AnyObject? { game }

	init(match: GKMatch, game: Game?) {
		self.match = match
		super.init()
		
		self.game = game
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
					MatchManager.instance.clearTurnBasedMatch()
				}
			}
		}
		match.disconnect()
	}
	
	public var turnBasedMatch: GKTurnBasedMatch? { nil }
	public var realTimeMatch: GKMatch? { match }

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
				self.game?.playersChanged(to: allPlayers)
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
			await MainActor.run { game?.matchPhaseChanged(to: newPhase, in: self) }
		}
	}
}

//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

public protocol SomeMatch: AnyObject { }

public protocol ActiveMatchDelegate {
	associatedtype GameState: Codable
	associatedtype GameUpdate: Codable
	
	func didReceive(data: Data, from player: GKPlayer)
	func loaded(match: ActiveMatch<Self>, with players: [GKPlayer])
	func playersChanged(to players: [GKPlayer])
	
	func startedMatch()
	func endedMatch()
}

public class ActiveMatch<Delegate: ActiveMatchDelegate>: NSObject, ObservableObject, GKMatchDelegate, SomeMatch {
	public let match: GKMatch
	public var delegate: Delegate?
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
		try? send(message: MessageMatchStart())
	}
	
	func endMatchLocally() {
		Task {
			await MainActor.run {
				if MatchManager.instance.activeMatch === self {
					MatchManager.instance.activeMatch = nil
				}
			}
		}
		match.disconnect()
	}
	
	public func endMatch() {
		try? send(message: MessageMatchEnd())
		endMatchLocally()
	}
	
	func sendUpdate(_ update: Delegate.GameUpdate, reliably: Bool = true) throws {
		try send(message: MessageMatchUpdate(update), reliably: reliably)
	}
	
	func sendState(_ state: Delegate.GameState, reliably: Bool = true) throws {
		try send(message: MessageMatchState(state), reliably: reliably)
	}
	
	func send<Message: MatchMessage>(message: Message, reliably: Bool = true) throws {
		let data = try JSONEncoder().encode(message)
		do {
			try send(data: data, reliably: reliably)
		} catch {
			recentErrors.append(error)
			throw error
		}
	}
	
	func send(data: Data, reliably: Bool = true) throws {
		try match.sendData(toAllPlayers: data, with: reliably ? .reliable : .unreliable)
	}

	public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
		Task {
			await MainActor.run {
				self.delegate?.playersChanged(to: allPlayers)
			}
		}
	}
	
	public func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
		 return true
	}

	public func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
		do {
			let raw = try JSONDecoder().decode(RawMessage.self, from: data)
			
			switch raw.kind {
			case .start: delegate?.startedMatch()
			case .end:
				delegate?.endedMatch()
				endMatchLocally()
				
			default: break
			}
		} catch {
			recentErrors.append(error)
			print("Failed to process a message: \(String(data: data, encoding: .utf8) ?? "--")")
		}
	}
}

extension ActiveMatch {
	public struct ReceivedData {
		let receivedAt = Date()
		let data: Data
	}
}

//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit

public protocol SomeTurnBasedActiveMatch: SomeMatch {
	func receivedTurn(for player: GKPlayer, didBecomeActive: Bool)
	func matchEnded(for player: GKPlayer)
	func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange)
	func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange)
	func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange)
	func quitRequest(from player: GKPlayer)
}

enum TurnBasedError: Error { case noMatchGame }

public class TurnBasedActiveMatch<Game: TurnBasedGame>: NSObject, ObservableObject, SomeTurnBasedActiveMatch {
	public let match: GKTurnBasedMatch
	public var game: Game?
	public var parentGame: AnyObject? { game }
	public var currentPlayer: GKPlayer? { match.currentParticipant?.player }
	public var nextPlayers: [GKPlayer] {
		guard let current = match.currentParticipant, let currentIndex = match.participants.firstIndex(of: current) else { return match.participants.compactMap { $0.player }}
		
		let count = match.participants.count
		let participants = match.participants.indices.dropFirst().map { match.participants[($0 + currentIndex) % count] }
		
		return participants.compactMap { $0.player }
	}
	
	init(match: GKTurnBasedMatch, game: Game?) {
		self.match = match
		self.game = game
	}
	
	public var isLocalPlayersTurn: Bool { match.currentParticipant?.player == GKLocalPlayer.local }
	
	public func endTurn(nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		guard let payload = game?.gameState else { throw TurnBasedError.noMatchGame }
		let data = try JSONEncoder().encode(payload)

		var partipants = nextPlayers?.mapToParticpants(in: match) ?? nextPlayerArray
		if partipants.isEmpty { partipants = match.participants }
		
		try await match.endTurn(withNextParticipants: partipants, turnTimeout: timeOut, match: data)
		objectWillChange.send()
	}
	
	var nextPlayerArray: [GKTurnBasedParticipant] {
		guard let current = match.currentParticipant, let index = match.participants.firstIndex(of: current) else { return [] }
		
		return [match.participants[(index + 1) % match.participants.count]]
	}

	public var turnBasedMatch: GKTurnBasedMatch? { match }
	public var realTimeMatch: GKMatch? { nil }
	
	public func receivedTurn(for player: GKPlayer, didBecomeActive: Bool) {
		do {
			if let data = match.matchData {
				let payload = try JSONDecoder().decode(Game.GameState.self, from: data)
				game?.received(gameState: payload)
			} else {
				game?.received(gameState: nil)
			}
		} catch {
			print("Failed to decode Game State: \(error)")
		}
	}
	
	public func matchEnded(for player: GKPlayer) {
		
	}

	public func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange) {
		
	}
	
	public func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange) {
		
	}
	
	public func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange) {
	}
	
	public func quitRequest(from player: GKPlayer) {
		
	}

}

extension Array where Element == GKPlayer {
	func mapToParticpants(in match: GKTurnBasedMatch) -> [GKTurnBasedParticipant] {
		compactMap { player in match.participants.first(where: { $0 == player })}
	}
}

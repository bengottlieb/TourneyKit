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
	public weak var game: Game?
	let manager: MatchManager
	public var parentGame: AnyObject? { game }
	public var currentPlayer: GKPlayer? { match.currentParticipant?.player }
	public var nextPlayers: [GKPlayer] {
		guard let current = match.currentParticipant, let currentIndex = match.participants.firstIndex(of: current) else { return match.participants.compactMap { $0.player }}
		
		let count = match.participants.count
		let participants = match.participants.indices.dropFirst().map { match.participants[($0 + currentIndex) % count] }
		
		return participants.compactMap { $0.player }
	}
	
	init(match: GKTurnBasedMatch, game: Game?, matchManager: MatchManager) {
		self.match = match
		self.game = game
		self.manager = matchManager
	}
	
	public var isLocalPlayersTurn: Bool { match.currentParticipant?.player == GKLocalPlayer.local }
	
	public func endTurn(nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		try await match.endTurn(withNextParticipants: nextParticipants(startingWith: nextPlayers), turnTimeout: timeOut, match: try matchData)
		objectWillChange.send()
	}
	
	public func resign(withOutcome outcome: GKTurnBasedMatch.Outcome, nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		try await match.participantQuitInTurn(with: outcome, nextParticipants: nextParticipants(startingWith: nextPlayers), turnTimeout: timeOut, match: try matchData)
	}
	
	public var turnBasedMatch: GKTurnBasedMatch? { match }
	public var realTimeMatch: GKMatch? { nil }
	
}

extension TurnBasedActiveMatch {
	public var matchData: Data {
		get throws {
			guard let payload = game?.gameState else { throw TurnBasedError.noMatchGame }
			let data = try JSONEncoder().encode(payload)
			return data
		}
	}
	
	func nextParticipants(startingWith next: [GKPlayer]?) -> [GKTurnBasedParticipant] {
		var partipants = next?.mapToParticpants(in: match)
		if partipants == nil {
			guard let current = match.currentParticipant, let index = match.participants.firstIndex(of: current) else { return [] }
			
			partipants = [match.participants[(index + 1) % match.participants.count]]
		}
		if partipants?.isEmpty != false { partipants = match.participants }
		return partipants!
	}
}

extension TurnBasedActiveMatch {
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
		game?.matchEndedOnGameCenter()
	}

	public func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange) {
		
	}
	
	public func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange) {
		
	}
	
	public func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange) {
	}
	
	public func quitRequest(from player: GKPlayer) {
		game?.playerDropped(player)
	}

}

extension Array where Element == GKPlayer {
	func mapToParticpants(in match: GKTurnBasedMatch) -> [GKTurnBasedParticipant] {
		compactMap { player in match.participants.first(where: { $0 == player })}
	}
}

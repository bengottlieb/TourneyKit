//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit

public protocol SomeTurnBasedActiveMatch: SomeMatch {
	func receivedTurn(for player: GKPlayer, didBecomeActive: Bool, in match: GKTurnBasedMatch)
	func matchEnded(for player: GKPlayer, in match: GKTurnBasedMatch)
	func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch)
	func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch)
	func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch)
	func quitRequest(from player: GKPlayer, in match: GKTurnBasedMatch)
}

enum TurnBasedError: Error { case noMatchGame, triedToEndGameWhenItsNotYourTurn, triedToEndGameWhenNotPlaying }

public class TurnBasedActiveMatch<Game: TurnBasedGame>: NSObject, ObservableObject, SomeTurnBasedActiveMatch {
	public var match: GKTurnBasedMatch
	public weak var game: Game?
	let manager: MatchManager
	public var parentGame: AnyObject? { game }
	public var currentPlayer: GKPlayer? { match.currentParticipant?.player }
	public var status: GKTurnBasedMatch.Status { isLocalPlayerPlaying ? match.status : .ended }
	public var isCurrentPlayersTurn: Bool { currentPlayer == GKLocalPlayer.local }
	public var currentPlayers: [GKPlayer] {
		match.participants.compactMap { $0.player }
	}

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
	
	public var isLocalPlayersTurn: Bool { match.isLocalPlayersTurn }
	public var isLocalPlayerPlaying: Bool { match.isLocalPlayerPlaying }
	public var localParticipant: GKTurnBasedParticipant? { match.localParticipant }
	
	public func endTurn(nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		try await match.endTurn(withNextParticipants: nextParticipants(startingWith: nextPlayers), turnTimeout: timeOut, match: try matchData)
		objectWillChange.send()
	}
	
	public func resign(withOutcome outcome: GKTurnBasedMatch.Outcome, nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		try await reloadMatch()
		let next = nextParticipants(startingWith: nextPlayers)
		
		if !isLocalPlayerPlaying {
			throw TurnBasedError.triedToEndGameWhenNotPlaying
		} else if next.count <= 1 { 	// no more players, end the game
			match.currentParticipant?.matchOutcome = .second
			next.first?.matchOutcome = .won
			if !isCurrentPlayersTurn { throw TurnBasedError.triedToEndGameWhenItsNotYourTurn }
			try await match.endMatchInTurn(withMatch: matchData)
		} else if isCurrentPlayersTurn {
			try await match.participantQuitInTurn(with: outcome, nextParticipants: next, turnTimeout: timeOut, match: try matchData)
		} else {
			try await match.participantQuitOutOfTurn(with: outcome)
		}
		try await reloadMatch()
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
	
	public var currentGameState: Game.GameState {
		get throws {
			try JSONDecoder().decode(Game.GameState.self, from: matchData)
		}
	}
	
	public func reloadMatch() async throws {
		try await match.loadMatchData()
	}
	
	func nextParticipants(startingWith next: [GKPlayer]?) -> [GKTurnBasedParticipant] {
		var partipants = next?.mapToParticpants(in: match)
		if partipants == nil {
			guard let current = match.currentParticipant, let index = match.participants.firstIndex(of: current) else { return [] }
			
			partipants = [match.participants[(index + 1) % match.participants.count]]
		}
		if partipants?.isEmpty != false { partipants = match.participants }
		return partipants!.filter { $0.status == .active || $0.status == .matching }
	}
}

extension TurnBasedActiveMatch {
	public func receivedTurn(for player: GKPlayer, didBecomeActive: Bool, in match: GKTurnBasedMatch) {
		self.match = match
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
	
	public func matchEnded(for player: GKPlayer, in match: GKTurnBasedMatch) {
		self.match = match
		game?.matchEndedOnGameCenter()
	}

	public func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch) {
		self.match = match
		(game as? (any TurnBasedGameExchange))?.receivedExchangeRequest(exchange)
	}
	
	public func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch) {
		self.match = match
		(game as? (any TurnBasedGameExchange))?.cancelledExchangeRequest(exchange)
	}
	
	public func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch) {
		self.match = match
		(game as? (any TurnBasedGameExchange))?.repliedToExchangeRequest(exchange, with: replies)
	}
	
	public func quitRequest(from player: GKPlayer, in match: GKTurnBasedMatch) {
		self.match = match
		DispatchQueue.main.async {
			self.game?.playerDropped(player)
		}
	}

}

extension Array where Element == GKPlayer {
	func mapToParticpants(in match: GKTurnBasedMatch) -> [GKTurnBasedParticipant] {
		compactMap { player in match.participants.first(where: { $0 == player })}
	}
}

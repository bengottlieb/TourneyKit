//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit

@MainActor public protocol SomeTurnBasedActiveMatch: SomeGameKitMatch {
	func receivedTurn(for player: GKPlayer, didBecomeActive: Bool, in match: GKTurnBasedMatch)
	func matchEnded(for player: GKPlayer, in match: GKTurnBasedMatch)
	func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch)
	func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch)
	func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, in match: GKTurnBasedMatch)
	func quitRequest(from player: GKPlayer, in match: GKTurnBasedMatch)
}

enum TurnBasedError: Error { case noMatchGame, triedToEndGameWhenNotPlaying, noMatchData }

@MainActor @Observable public class TurnBasedActiveMatch<Game: TurnBasedContainer>: NSObject, SomeTurnBasedActiveMatch {
	public var match: GKTurnBasedMatch
	@ObservationIgnored public weak var game: Game?
	@ObservationIgnored let manager: MatchManager
	public var parentGame: AnyObject? { game }
	public var currentPlayer: GKPlayer? { match.currentParticipant?.player }
	public var status: GKTurnBasedMatch.Status { isLocalPlayerPlaying ? match.status : .ended }
	public var isCurrentPlayersTurn: Bool { currentPlayer == GKLocalPlayer.local }
	public var allPlayers: [GKPlayer] { match.participants.compactMap { $0.player } }
	public var activePlayers: [GKPlayer] { match.participants.filter { $0.matchOutcome == .none }.compactMap { $0.player } }
	
	public var nextPlayers: [GKPlayer] {
		guard let current = match.currentParticipant, let currentIndex = match.participants.firstIndex(of: current) else { return match.participants.compactMap { $0.player }}
		
		let count = match.participants.count
		let participants = match.participants.indices.dropFirst().map { match.participants[($0 + currentIndex) % count] }
		
		return participants.compactMap { $0.player }
	}
	
	public init(match: GKTurnBasedMatch, game: Game?, matchManager: MatchManager) {
		self.match = match
		self.game = game
		self.manager = matchManager
	}
	
	public func player(withTag tag: GKPlayer.PlayerTag?) -> GKPlayer? { match.participants.compactMap { $0.player }[tag] }
	public var isLocalPlayersTurn: Bool { match.isLocalPlayersTurn }
	public var isLocalPlayerPlaying: Bool { match.isLocalPlayerPlaying }
	public var localParticipant: GKTurnBasedParticipant? { match.localParticipant }
	
	public func endTurn(nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		let participants = nextParticipants(startingWith: nextPlayers)
		tourneyLogger.info("Ending turn, next: \(participants.map { $0.player?.displayName ?? "Unnamed Player" }.joined(separator: ", "))")
		try await match.endTurn(withNextParticipants: participants, turnTimeout: timeOut, match: try localMatchData)
		MatchManager.instance.replace(match)
	}
	
	public func endGame(withOutcome outcome: GKTurnBasedMatch.Outcome, nextPlayers: [GKPlayer]? = nil, timeOut: TimeInterval = 60.0) async throws {
		let matchData = try localMatchData
		try await reloadMatch(loadingData: false)

		if !isLocalPlayerPlaying {
			throw TurnBasedError.triedToEndGameWhenNotPlaying
		} else if isCurrentPlayersTurn {
			let next = nextParticipants(startingWith: nextPlayers)
			if next.isEmpty {
				localParticipant?.matchOutcome = outcome
				try await match.endMatchInTurn(withMatch: matchData)
			} else {
				try await match.participantQuitInTurn(with: outcome, nextParticipants: next, turnTimeout: timeOut, match: matchData)
			}
		} else {
			try await match.participantQuitOutOfTurn(with: outcome)
		}
		try await reloadMatch()
	}
	
	public var turnBasedMatch: GKTurnBasedMatch? { match }
	public var realTimeMatch: GKMatch? { nil }
	
}

extension TurnBasedActiveMatch {
	public var localMatchData: Data {
		get throws {
			guard let payload = game?.matchState else { throw TurnBasedError.noMatchGame }
			let data = try JSONEncoder().encode(payload)
			return data
		}
	}
	
	public var remoteMatchData: Data {
		get throws {
			guard let data = match.matchData else { throw TurnBasedError.noMatchData }
			return data
		}
	}
	
	public var localMatchState: Game.MatchState {
		get throws {
			try JSONDecoder().decode(Game.MatchState.self, from: localMatchData)
		}
	}

	public var remoteMatchState: Game.MatchState {
		get throws {
			try JSONDecoder().decode(Game.MatchState.self, from: remoteMatchData)
		}
	}

	public func reloadMatch() async throws {
		try await reloadMatch(loadingData: true)
	}
	
	func reloadMatch(loadingData: Bool) async throws {
		try await match.loadMatchData()
		if loadingData, let data = match.matchData {
			let newState = try JSONDecoder().decode(Game.MatchState.self, from: data)

			game?.received(matchState: newState)
		}
		MatchManager.instance.replace(match)
	}

	func nextParticipants(startingWith next: [GKPlayer]?) -> [GKTurnBasedParticipant] {
		var participants = next?.mapToParticipants(in: match)
		if participants == nil {
			guard let current = match.currentParticipant, let index = match.participants.firstIndex(of: current) else { return [] }
			
			participants = [match.participants[(index + 1) % match.participants.count]]
		}
		if participants?.isEmpty != false { participants = match.participants }
		return (participants ?? []).filter { $0.status == .active || $0.status == .matching }
	}
}

extension TurnBasedActiveMatch {
	public func receivedTurn(for player: GKPlayer, didBecomeActive: Bool, in match: GKTurnBasedMatch) {
		self.match = match
		do {
			if let data = match.matchData {
				let payload = try JSONDecoder().decode(Game.MatchState.self, from: data)
				game?.received(matchState: payload)
			} else {
				game?.received(matchState: nil)
			}
		} catch {
			tourneyLogger.error("Failed to decode Game State: \(error)")
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
		self.game?.playerDropped(player)
	}
	
	public func removeMatch() async throws {
		try await match.remove()
		MatchManager.instance.removeMatch(match)
	}

}

extension Array where Element == GKPlayer {
	func mapToParticipants(in match: GKTurnBasedMatch) -> [GKTurnBasedParticipant] {
		compactMap { player in match.participants.first(where: { $0.player == player })}
	}
	
	public subscript(tag: GKPlayer.PlayerTag?) -> GKPlayer? {
		guard let index = map({ $0.playerTag }).firstIndex(tag: tag) else { return nil }
		return self[index]
	}
}

extension Array where Element == GKPlayer.PlayerTag {
	public func firstIndex(tag: GKPlayer.PlayerTag?) -> Int? {
		guard let tag else { return nil }
		for index in indices {
			if self[index].teamID == tag.teamID { return index }
		}
		
		for index in indices {
			if self[index].gameID == tag.gameID { return index }
		}
		
		for index in indices {
			if self[index].alias == tag.alias { return index }
		}
		
		return nil
	}
}

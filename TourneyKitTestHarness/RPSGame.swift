//
//  RPSGame.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import TourneyKit
import GameKit

final class RPSGame: ActiveMatchDelegate, ObservableObject {
	
	@Published var state: GameState = GameState(currentPlayerID: "")
	@Published var players: [GKPlayer] = []
	@Published var isStarted = false
	var match: ActiveMatch<RPSGame>?
	
	struct GameState: Codable {
		var currentPlayerID: String
		var playerCount = 0
		var moves: [Move] = []
		
		var localPlayerID: String { GKLocalPlayer.local.teamPlayerID }
		
		var hasMovedThisTurn: Bool {
			guard let recentMove = moves.last else { return false }
			if recentMove.moves.count == playerCount { return false }
			return recentMove.moves[localPlayerID] != nil
		}
		
		mutating func addMove(_ move: String) {
			if hasMovedThisTurn { return }
			
			if let recentMove = moves.last, recentMove.moves[localPlayerID] == nil {
				moves[moves.count - 1].moves[localPlayerID] = move
			} else {
				moves.append(.init(moves: [localPlayerID: move]))
			}
		}
		
		struct Move: Codable {
			var moves: [String: String] = [:]
		}
	}
	
	var canMove: Bool { !state.hasMovedThisTurn }
	
	func makeMove(_ move: String) {
		state.addMove(move)
		try? match?.sendState(state)
	}
	
	struct GameUpdate: Codable {
	}
	
	func loaded(match: ActiveMatch<RPSGame>, with players: [GKPlayer]) {
		self.match = match
		self.isStarted = true
	}
	
	func matchPhaseChanged(to phase: ActiveMatchPhase, in match: ActiveMatch<RPSGame>) {
		objectWillChange.send()

		switch phase {
		case .loaded:
			break

		case .playing:
			isStarted = true
			
		case .ended:
			isStarted = false
			
		default: break
		}
	}
	
	
	@MainActor func endGame() {
		objectWillChange.send()
		match?.endMatch()
	}

	@MainActor func terminateGame() {
		objectWillChange.send()
		isStarted = false
		match?.terminate()
	}

	
	func didReceive(data: Data, from player: GKPlayer) {
		do {
			state = try JSONDecoder().decode(GameState.self, from: data)
		} catch {
			print("Failed to decode incoming data: \(error)")
		}
	}
	
	func playersChanged(to players: [GKPlayer]) {
		self.players = players
		state.playerCount = players.count
	}
	
	func matchStateChanged(to state: GameState) {
		self.state = state
	}

	func matchUpdated(with update: GameUpdate) {
		
	}

	func endedMatch() {
		isStarted = false
		match?.terminate()
	}

	var request: GKMatchRequest {
		let request = GKMatchRequest()
		request.playerRange = 2...2
		return request
	}
}

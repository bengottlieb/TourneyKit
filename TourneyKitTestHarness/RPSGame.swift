//
//  RPSGame.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import TourneyKit
import GameKit

class RPSGame: ActiveMatchDelegate, ObservableObject {
	@Published var state: GameState = GameState(currentPlayerID: "")
	@Published var players: [GKPlayer] = []
	@Published var isStarted = false
	var match: ActiveMatch?
	
	struct GameState: Codable {
		var currentPlayerID: String
		var moves: [Move] = []
		
		struct Move: Codable {
			let player: String
			let move: String
		}
	}
	
	func started(with players: [GKPlayer], in match: ActiveMatch) {
		self.players = players
		self.isStarted = true
		self.match = match
	}
	
	@MainActor func endGame() {
		match?.endMatch()
		isStarted = false
	}
	
	func didReceive(data: Data, from player: GKPlayer, in match: ActiveMatch) {
		do {
			state = try JSONDecoder().decode(GameState.self, from: data)
		} catch {
			print("Failed to decode incoming data: \(error)")
		}
	}
	
	func playersChanged(to players: [GKPlayer], in: ActiveMatch) {
		self.players = players
	}
	
	func started(match: ActiveMatch) {
		isStarted = true
	}
	
	func ended(match: ActiveMatch) {
		isStarted = false
	}

	var request: GKMatchRequest {
		let request = GKMatchRequest()
		request.playerRange = 2...2
		return request
	}
}

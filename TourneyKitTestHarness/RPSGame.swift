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
		var moves: [Move] = []
		
		struct Move: Codable {
			let player: String
			let move: String
		}
	}
	
	struct GameUpdate: Codable {
	}
	
	func loaded(match: ActiveMatch<RPSGame>, with players: [GKPlayer]) {
		self.players = players
		self.isStarted = true
		self.match = match
	}
	
	@MainActor func endGame() {
		match?.endMatch()
		isStarted = false
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
	}
	
	func startedMatch() {
		isStarted = true
	}
	
	func endedMatch() {
		isStarted = false
	}

	var request: GKMatchRequest {
		let request = GKMatchRequest()
		request.playerRange = 2...2
		return request
	}
}

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
	}
	
	
	func didReceive(data: Data, from player: GKPlayer, in match: ActiveMatch) {
		do {
			state = try JSONDecoder().decode(GameState.self, from: data)
		} catch {
			print("Failed to decode incoming data: \(error)")
		}
	}
	
	var request: GKMatchRequest {
		let request = GKMatchRequest()
		request.playerRange = 2...2
		return request
	}
}

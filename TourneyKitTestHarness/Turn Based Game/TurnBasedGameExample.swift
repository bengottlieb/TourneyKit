//
//  TurnBasedGameExample.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit
import TourneyKit

final class TurnBasedGameExample: TurnBasedGame, ObservableObject {
	typealias GameState = TurnBasedGameExampleState
	
	var match: TurnBasedActiveMatch<TurnBasedGameExample>?
	var gameState = TurnBasedGameExampleState()
	
	static var defaultRequest: GKMatchRequest {
		let request = GKMatchRequest()
		request.minPlayers = 2
		request.maxPlayers = 2
		return request
	}
	
	func loaded(match: TourneyKit.TurnBasedActiveMatch<TurnBasedGameExample>) {
		self.match = match
	}
	
	func received(gameState: GameState?) {
		if let gameState {
			print("Received game state: \(gameState)")
		}
		objectWillChange.send()
	}
	
	func endTurn() async {
		do {
			try await match?.endTurn()
			objectWillChange.send()
		} catch {
			print("Failed to end turn: \(error)")
		}
	}
	
	func matchEndedOnGameCenter() {
		print("Game over, man. Game over!")
	}
	
	func playerDropped(_ player: GKPlayer) {
		print("\(player.displayName) has dropped the game.")
	}
}


struct TurnBasedGameExampleState: Codable {
	
}

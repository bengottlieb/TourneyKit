//
//  TurnBasedGameExample.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit
import TourneyKit

final class TurnBasedGameExample: TurnBasedMatch, ObservableObject {
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
	
	func clearOut() { }

	func received(gameState: GameState?) {
		objectWillChange.send()
	}
	
	func endTurn() async {
		do {
			try await match?.endTurn()
			objectWillChange.send()
		} catch {
			appLogger.info("Failed to end turn: \(error)")
		}
	}
	
	func matchEndedOnGameCenter() {
		appLogger.info("Game over, man. Game over!")
		objectWillChange.send()
	}
	
	func playerDropped(_ player: GKPlayer) {
		appLogger.info("\(player.displayName) has dropped the game.")
		objectWillChange.send()
	}
}


struct TurnBasedGameExampleState: Codable {
	var message = "Hello"
}

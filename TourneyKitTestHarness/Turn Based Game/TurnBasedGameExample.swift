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
}


struct TurnBasedGameExampleState: Codable {
	
}

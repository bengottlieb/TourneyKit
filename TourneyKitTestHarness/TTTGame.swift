//
//  TTTGame.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit
import TourneyKit

final class TTTGame: TurnBasedActiveMatchDelegate, ObservableObject {
	typealias GameState = TTTGameState
	
	var match: TurnBasedActiveMatch<TTTGame>?
	var gameState = TTTGameState()
	
	func loaded(match: TourneyKit.TurnBasedActiveMatch<TTTGame>) {
		self.match = match
	}
	
	func received(gameState: GameState?) {
		print("Received game state: \(gameState)")
		objectWillChange.send()
	}
}


struct TTTGameState: Codable {
	
}

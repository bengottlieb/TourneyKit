//
//  TurnBasedMatch.swift
//  
//
//  Created by Ben Gottlieb on 5/22/23.
//

import SwiftUI
import GameKit
import Observation

public protocol TurnBasedMatch: Observable, AnyObject {
	associatedtype GameState: Codable
	
	var gameState: GameState { get set }
	func loaded(match: TurnBasedActiveMatch<Self>)
	func received(gameState: GameState?)
	func matchEndedOnGameCenter()
	func playerDropped(_ player: GKPlayer)
	func clearOut()

	static var defaultRequest: GKMatchRequest { get }
}

public protocol TurnBasedMatchExchange: TurnBasedMatch {
	func receivedExchangeRequest(_ request: GKTurnBasedExchange)
	func cancelledExchangeRequest(_ exchange: GKTurnBasedExchange)
	func repliedToExchangeRequest(_ exchange: GKTurnBasedExchange, with replies: [GKTurnBasedExchangeReply])
}

extension GKTurnBasedMatch.Status: @retroactive CustomStringConvertible {
	public var description: String {
		switch self {
		case .unknown: return "unknown"
		case .open: return "playing"
		case .ended: return "over"
		case .matching: return "matching"
			
		@unknown default:
			return "@unknown"
		}
	}
}

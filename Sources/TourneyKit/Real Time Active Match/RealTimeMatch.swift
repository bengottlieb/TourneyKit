//
//  RealTimeMatch.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import Foundation
import GameKit

@MainActor public protocol RealTimeMatch: AnyObject {
	associatedtype GameState: Codable
	associatedtype GameUpdate: Codable
	
	func didReceive(data: Data, from player: GKPlayer)
	func loaded(match: RealTimeActiveMatch<Self>, with players: [GKPlayer])
	func playersChanged(to players: [GKPlayer])
	func matchStateChanged(to state: GameState)
	func matchUpdated(with update: GameUpdate)

	func matchPhaseChanged(to phase: ActiveMatchPhase)
	func matchFailed(withError error: Error)
}

public extension RealTimeMatch {
	func matchFailed(withError error: Error) { }
}

public enum ActiveMatchPhase: String, Codable { case loading, playing, ended
	public var title: String {
		rawValue
	}
}

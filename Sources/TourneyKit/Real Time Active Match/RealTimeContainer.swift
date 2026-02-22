//
//  RealTimeContainer.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import Foundation
import GameKit

@MainActor public protocol RealTimeContainer: AnyObject {
	associatedtype MatchState: Codable
	associatedtype MatchUpdate: Codable
	
	func didReceive(data: Data, from player: GKPlayer)
	func loaded(match: RealTimeActiveMatch<Self>, with players: [GKPlayer])
	func playersChanged(to players: [GKPlayer])
	func matchStateChanged(to state: MatchState)
	func matchUpdated(with update: MatchUpdate)

	func matchPhaseChanged(to phase: ActiveMatchPhase)
	func matchFailed(withError error: Error)
}

public extension RealTimeContainer {
	func matchFailed(withError error: Error) { }
}

public enum ActiveMatchPhase: String, Codable { case loading, playing, ended
	public var title: String {
		rawValue
	}
}

//
//  GKPlayerConnectionState.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit


extension GKPlayerConnectionState: @retroactive CustomStringConvertible {
	public var description: String {
		switch self {
		case .connected: return "connected"
		case .disconnected: return "disconnected"
		
		case .unknown: return "unknown"
		@unknown default: return "@unknown"
		}
	}
}

extension GKTurnBasedParticipant.Status: @retroactive CustomStringConvertible {
	public var description: String {
		switch self {
		case .unknown: return "unknown"
		case .invited: return "invited"
		case .declined: return "declined"
		case .matching: return "matching"
		case .active: return "active"
		case .done: return "done"
		@unknown default: return "@unknown"
		}
	}
}

extension GKTurnBasedMatch.Outcome: @retroactive CustomStringConvertible {
	public var description: String {
		switch self {
		case .none: return "none"
		case .quit: return "quit"
		case .won: return "won"
		case .lost: return "lost"
		case .tied: return "tied"
		case .timeExpired: return "time expired"
		case .first: return "first"
		case .second: return "second"
		case .third: return "third"
		case .fourth: return "fourth"
		case .customRange: return "custom"
		@unknown default: return "@unknown"
		}
	}
}


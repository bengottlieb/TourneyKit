//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

extension GKMatchRequest: @retroactive Identifiable {
	
}

public extension GKMatchRequest {
	var playerRange: ClosedRange<Int> {
		get { minPlayers...maxPlayers }
		set {
			minPlayers = newValue.lowerBound
			maxPlayers = newValue.upperBound
		}
	}
}

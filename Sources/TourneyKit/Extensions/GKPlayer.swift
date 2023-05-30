//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import GameKit

public extension GKPlayer {
	var tourneyKitID: String? {
		playerID
		//PlayerCache.instance.id(for: self)
	}
	
	var isLocalPlayer: Bool {
		self == GKLocalPlayer.local
	}
}

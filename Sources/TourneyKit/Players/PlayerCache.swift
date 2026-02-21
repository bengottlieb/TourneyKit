//
//  PlayerCache.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit

public class PlayerCache {
	nonisolated(unsafe) static let instance = PlayerCache()
	
	struct Info {
		let id: String
		let name: String
	}
	
	var cache: [GKPlayer: Info] = [:]
	
	func set(name: String, id: String, for player: GKPlayer) {
		cache[player] = Info(id: id, name: name)
	}
	
	func name(for player: GKPlayer) -> String? { cache[player]?.name }
	func id(for player: GKPlayer) -> String? { cache[player]?.id }
}

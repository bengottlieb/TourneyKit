//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import GameKit

public extension GKPlayer {
	var playerTag: PlayerTag { PlayerTag(teamID: teamPlayerID, containerID: gamePlayerID, alias: alias) }

	var isLocalPlayer: Bool {
		self == GKLocalPlayer.local
	}
	
	var tourneyKitID: String {
		gamePlayerID
	}
}

extension GKPlayer {
	public struct PlayerTag: Codable, CustomStringConvertible, Equatable {
		public let teamID: String
		public let containerID: String
		public let alias: String
		
		public var hasTemporaryIDs: Bool { teamID.contains(":") || containerID.contains(":") }
		public var description: String {
			if hasTemporaryIDs { return "[\(alias)]" }
			return "\(alias) [\(teamID)]"
		}
	}
}

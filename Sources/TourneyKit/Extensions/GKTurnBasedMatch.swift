//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/28/23.
//

import GameKit

public extension GKTurnBasedMatch {
	var isLocalPlayersTurn: Bool {
		currentParticipant == localParticipant
	}
	
	var localParticipant: GKTurnBasedParticipant? {
		participants.first { $0.player == GKLocalPlayer.local }
	}
	
	var isLocalPlayerPlaying: Bool {
		localParticipant?.status == .active
	}
	
	var opponents: [GKPlayer] {
		participants.compactMap { $0.player }.filter { $0 != GKLocalPlayer.local }
	}
	
	var vsString: String {
		"vs " + opponents.map { $0.displayName }.joined(separator: ", ")
	}
	
	var lastTurnDate: Date? {
		participants.compactMap { $0.lastTurnDate }.sorted { $0 < $1 }.first
	}
	
	var isActive: Bool {
		if status == .ended { return false }
		
		if localParticipant?.status == .done { return false }
		return true
	}
	
	func player(withID id: String?) -> GKPlayer? {
		guard let id else { return nil }
		
		return participants.first { $0.player?.tourneyKitID == id }?.player
	}
}

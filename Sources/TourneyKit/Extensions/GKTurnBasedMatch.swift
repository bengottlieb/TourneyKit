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
	
	var localParticipent: GKTurnBasedParticipant? {
		participants.first { $0.player == GKLocalPlayer.local }
	}
	
	var isLocalPlayerPlaying: Bool {
		localParticipant?.status == .active
	}
}

//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/28/23.
//

import GameKit

public extension GKTurnBasedMatch {
	var localPlayerWon: Bool {
		guard let localParticipant else { return false }
		if localParticipant.matchOutcome == .won { return true }
		if localParticipant.matchOutcome == .lost { return false }
		
		let active = activeParticipants
		if active.count > 1 { return false }
		return active.contains(localParticipant)
	}
	
	var activeParticipants: [GKTurnBasedParticipant] {
		participants.filter { $0.matchOutcome == .none }
	}
	
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
		if opponents.isEmpty { return "--" }
		return "vs " + opponents.map { $0.displayName }.joined(separator: ", ")
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
	
	var statusString: String {
		if isActive {
			if let lastTurn = lastTurnDate {
				return "Last at \(lastTurn.playedAt)"
			}
			return "Not Played"
		}
		
		if let lastPlayed = lastTurnDate {
			if localPlayerWon { return "Won, \(lastPlayed.playedAt)" }
			if localPlayerWon { return "Lost, \(lastPlayed.playedAt)" }
		}
		return "Over"

	}
}
extension Date {
	var playedAt: String {
		if abs(timeIntervalSinceNow) < 1440 * 60 { return formatted(date: .omitted, time: .shortened) }
		if abs(timeIntervalSinceNow) < 2880 * 60 { return "Yesterday, \(formatted(date: .omitted, time: .shortened))" }
		return formatted(date: .abbreviated, time: .omitted)
	}
}

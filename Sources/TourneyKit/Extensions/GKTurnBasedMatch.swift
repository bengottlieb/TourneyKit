//
//  GKTurnBasedMatch.swift
//  
//
//  Created by Ben Gottlieb on 5/28/23.
//

import GameKit

extension GKTurnBasedMatch: Identifiable {
	public var id: String { matchID }
}

public extension GKTurnBasedMatch {
	var localPlayerWon: Bool {
		guard let localParticipant else { return false }
		if localParticipant.matchOutcome == .won { return true }
		if localParticipant.matchOutcome == .lost { return false }
		
		let active = activeParticipants
		if active.count > 1 { return false }
		return active.contains(localParticipant)
	}

	var localPlayerLost: Bool {
		guard let localParticipant else { return false }
		let outcome = localParticipant.matchOutcome
		let winOutcomes: [GKTurnBasedMatch.Outcome] = [.won, .first, .second, .third, .fourth]
		if (winOutcomes + [.tied, .none]).contains(outcome)  { return false }
		return true
	}

	var activeParticipants: [GKTurnBasedParticipant] {
		participants.filter { $0.matchOutcome == .none }
	}
	
	var isLocalPlayersTurn: Bool {
		isActive && currentParticipant == localParticipant
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
		if opponents.isEmpty { return isActive ? "Waiting for Opponents" : "--" }
		return "vs " + opponents.map { $0.displayName }.joined(separator: ", ")
	}
	
	var lastTurnDate: Date? {
		participants.compactMap { $0.lastTurnDate }.sorted { $0 < $1 }.first
	}
	
	var isActive: Bool {
		if status == .ended { return false }
		
		if localParticipant?.status == .done { return false }
		return participants.filter { $0.isActive }.count > 1
	}
	
	func player(withTag tag: GKPlayer.PlayerTag?) -> GKPlayer? {
		participants.compactMap { $0.player }[tag]
	}
	
	var wasAborted: Bool {
		status == .ended && opponents.isEmpty
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
	
	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? GKTurnBasedMatch else { return false }
		
		if other.matchData != matchData { return false }
		if other.participants.count != participants.count { return false }
		for i in participants.indices {
			if other.participants[i] != participants[i] { return false }
		}
		
		return true
	}
}

public extension GKTurnBasedParticipant {
	var isActive: Bool { return matchOutcome == .none }
	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? GKTurnBasedParticipant else { return false }
		
		return player == other.player && lastTurnDate == other.lastTurnDate && status == other.status
	}
}

extension Date {
	var playedAt: String {
		if abs(timeIntervalSinceNow) < 1440 * 60 { return formatted(date: .omitted, time: .shortened) }
		if abs(timeIntervalSinceNow) < 2880 * 60 { return "Yesterday, \(formatted(date: .omitted, time: .shortened))" }
		return formatted(date: .abbreviated, time: .omitted)
	}
}

extension Array where Element == GKTurnBasedMatch {
	func sortedByRecency() -> [Element] {
		sorted { match1, match2 in
			if match1.isActive != match2.isActive { return match1.isActive }
			return (match1.lastTurnDate ?? .now) > (match2.lastTurnDate ?? .now)
		}
	}
}

//
//  MatchManager.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import GameKit
import OSLog

let tourneyLogger = Logger(subsystem: "TourneyKit", category: "matches")

enum MatchManagerError: Error { case missingMatchID, restoreInProgress, alreadyHaveActiveMatch }

@MainActor public class MatchManager: NSObject, ObservableObject {
	public static let instance = MatchManager()
	
	@Published public var isAutomatching = false
	@Published public var loadingMatch = false
	@Published public var pendingMatchRequest: GKMatchRequest?
	public var activeMatches: [GKTurnBasedMatch] = []
	public var visibleMatches: [GKTurnBasedMatch] = []
	public var allMatches: [GKTurnBasedMatch] = []
	public var hideAbortedMatches = true { didSet { filterMatches(changed: true) }}
	public var turnBasedGameClass: (any TurnBasedGame.Type)?
	
	@AppStorage("last_match_id") public var lastMatchID: String?

	@Published public private(set) var realTimeActiveMatch: SomeMatch?
	@Published public private(set) var turnBasedActiveMatch: SomeTurnBasedActiveMatch?
	public var isInRealTimeMatch: Bool { realTimeActiveMatch != nil }
	
	override private init() {
		super.init()
	}
	
	public func cancelAutomatching() {
		if !isAutomatching { return }
		
		GKMatchmaker.shared().cancel()
		isAutomatching = false
	}
	
	public func load<Game: RealTimeGame>(match: GKMatch, game: Game) {
		let active = RealTimeActiveMatch(match: match, game: game, matchManager: self)
		self.realTimeActiveMatch = active
		game.loaded(match: active, with: active.allPlayers)
		isAutomatching = false
	}
	
	public func load<Game: TurnBasedGame>(match: GKTurnBasedMatch, game: Game) {
		objectWillChange.send()
		replace(match)
		game.clearOut()
		let active = TurnBasedActiveMatch(match: match, game: game, matchManager: self)
		self.turnBasedActiveMatch = active
		game.loaded(match: active)
		lastMatchID  = match.matchID
		isAutomatching = false
	}
	
	public func reloadActiveGames() async throws {
		allMatches = try await GKTurnBasedMatch.loadMatches()
		filterMatches(changed: true)
		tourneyLogger.notice("Fetched \(self.allMatches.count), \(self.visibleMatches.count) visible, \(self.activeMatches.count) active")
	}
	
	func filterMatches(changed: Bool = false) {
		allMatches = allMatches.sortedByRecency()
		visibleMatches = hideAbortedMatches ? allMatches.filter { !$0.wasAborted } : allMatches
		activeMatches = allMatches.filter { $0.isActive }
		if changed { objectWillChange.send() }
	}
	
	@MainActor public func clearRealTimeMatch() {
		realTimeActiveMatch = nil
	}
	
	@MainActor public func clearTurnBasedMatch() {
		turnBasedActiveMatch = nil
	}
	
	func replace(_ match: GKTurnBasedMatch) {
		var hasChanged: Bool
		if let index = allMatches.firstIndex(where: { $0.matchID == match.matchID }) {
			hasChanged = match != allMatches[index]
			allMatches[index] = match
		} else {
			hasChanged = true
			allMatches.append(match)
		}
		
		filterMatches(changed: hasChanged)
	}
	
	public func startAutomatching<Game: RealTimeGame>(request: GKMatchRequest, game: Game) async throws {
		if isAutomatching { return }
		
		isAutomatching = true
		do {
			let match = try await GKMatchmaker.shared().findMatch(for: request)
			load(match: match, game: game)
		} catch {
			isAutomatching = false
			tourneyLogger.error("Failed to find match: \(error)")
			throw error
		}
	}
	
	public var canRestoreMatch: Bool { lastMatchID != nil }
	public func restore<Game: TurnBasedGame>(matchID: String? = nil, game: Game) async throws {
		guard turnBasedActiveMatch == nil else { throw MatchManagerError.alreadyHaveActiveMatch }
		guard !loadingMatch else { throw MatchManagerError.restoreInProgress }
		guard let id = matchID ?? lastMatchID else { throw MatchManagerError.missingMatchID }
		loadingMatch = true
		let match = try await GKTurnBasedMatch.load(withID: id)
		
		load(match: match, game: game)
		loadingMatch = false
	}
	
	func removeMatch(_ match: GKTurnBasedMatch) {
		if let index = allMatches.firstIndex(where: { $0.matchID == match.matchID }) {
			allMatches.remove(at: index)
			filterMatches(changed: true)

		}
	}
}

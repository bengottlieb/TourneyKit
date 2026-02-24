//
//  RemoteMatchManager.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import GameKit
import OSLog
import Achtung

let tourneyLogger = Logger(subsystem: "TourneyKit", category: "matches")

enum MatchManagerError: Error { case missingMatchID, restoreInProgress, alreadyHaveActiveMatch }

@MainActor @Observable public class RemoteMatchManager: NSObject {
	public static let instance = RemoteMatchManager()

	public var isAutomatching = false
	public var loadingMatch = false
	public var pendingMatchRequest: GKMatchRequest?
	public var activeMatches: [GKTurnBasedMatch] = []
	public var visibleMatches: [GKTurnBasedMatch] = []
	public var allMatches: [GKTurnBasedMatch] = []
	public var hideAbortedMatches = true { didSet { filterMatches() }}
	public var turnBasedGameClass: (any TurnBasedContainer.Type)?
	public var loadingError: Error?
	public var showErrors = true
	public var hasLoaded = false

	@ObservationIgnored @AppStorage("last_match_id") public var lastMatchID: String?
	@ObservationIgnored private var retainedRealTimeGame: AnyObject?
	@ObservationIgnored private var retainedTurnBasedGame: AnyObject?

	public private(set) var realTimeActiveMatch: SomeGameKitMatch?
	public private(set) var turnBasedActiveMatch: SomeTurnBasedActiveMatch?
	public var isInRealTimeMatch: Bool { realTimeActiveMatch != nil }
	public var canStartNewRealTimeMatch: Bool { GameCenterInterface.instance.isAuthenticated && RemoteMatchManager.instance.loadingError == nil }
	
	override private init() {
		super.init()
	}
	
	public func setup() {
		Task {
			if await GameCenterInterface.instance.authenticate() {
				await self.reloadActiveGames()
			}
		}
	}
	
	public func cancelAutomatching() {
		if !isAutomatching { return }
		
		GKMatchmaker.shared().cancel()
		isAutomatching = false
	}
	
	public func load<Game: RealTimeContainer>(match: GKMatch, game: Game) {
		retainedRealTimeGame = game
		let active = RealTimeActiveMatch(match: match, game: game, matchManager: self)
		self.realTimeActiveMatch = active
		game.loaded(match: active, with: active.allPlayers)
		isAutomatching = false
	}

	public func load<Game: TurnBasedContainer>(match: GKTurnBasedMatch, game: Game) {
		retainedTurnBasedGame = game
		replace(match)
		game.clearOut()
		let active = TurnBasedActiveMatch(match: match, game: game, matchManager: self)
		self.turnBasedActiveMatch = active
		game.loaded(match: active)
		lastMatchID  = match.matchID
		isAutomatching = false
	}
	
	public func reloadActiveGames() async {
		do {
			allMatches = try await GKTurnBasedMatch.loadMatches()
			filterMatches()
			tourneyLogger.notice("Fetched \(self.allMatches.count), \(self.visibleMatches.count) visible, \(self.activeMatches.count) active")
			loadingError = nil
			hasLoaded = true
		} catch {
			if showErrors, (loadingError as? NSError) != (error as NSError) {
				await Achtung.show(error)
			}
			loadingError = error
			print("Failed to reload active games: \(error.localizedDescription)")
		}
	}
	
	func filterMatches() {
		let sorted = allMatches.sortedByRecency()
		visibleMatches = hideAbortedMatches ? sorted.filter { !$0.wasAborted } : sorted
		activeMatches = sorted.filter { $0.isActive }
	}
	
	@MainActor public func clearRealTimeMatch() {
		realTimeActiveMatch = nil
		retainedRealTimeGame = nil
	}

	@MainActor public func clearTurnBasedMatch() {
		turnBasedActiveMatch = nil
		retainedTurnBasedGame = nil
	}
	
	func replace(_ match: GKTurnBasedMatch) {
		if let index = allMatches.firstIndex(where: { $0.matchID == match.matchID }) {
			allMatches[index] = match
		} else {
			allMatches.append(match)
		}
		filterMatches()
	}
	
	public func startAutomatching<Game: RealTimeContainer>(request: GKMatchRequest, game: Game) async throws {
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
	public func restore<Game: TurnBasedContainer>(matchID: String? = nil, game: Game) async throws {
		guard turnBasedActiveMatch == nil else { throw MatchManagerError.alreadyHaveActiveMatch }
		guard !loadingMatch else { throw MatchManagerError.restoreInProgress }
		guard let id = matchID ?? lastMatchID else { throw MatchManagerError.missingMatchID }
		loadingMatch = true
		defer { loadingMatch = false }
		let match = try await GKTurnBasedMatch.load(withID: id)
		load(match: match, game: game)
	}
	
	func removeMatch(_ match: GKTurnBasedMatch) {
		if let index = allMatches.firstIndex(where: { $0.matchID == match.matchID }) {
			allMatches.remove(at: index)
			filterMatches()

		}
	}
}

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
	public var turnBasedContainerClass: (any TurnBasedContainer.Type)?
	public var loadingError: Error?
	public var showErrors = true
	public var hasLoaded = false

	@ObservationIgnored @AppStorage("last_match_id") public var lastMatchID: String?
	@ObservationIgnored private var retainedRealTimeContainer: AnyObject?
	@ObservationIgnored private var retainedTurnBasedContainer: AnyObject?

	public private(set) var realTimeActiveMatch: SomeGameKitMatch?
	public private(set) var turnBasedActiveMatch: SomeTurnBasedActiveMatch?
	public var isInRealTimeMatch: Bool { realTimeActiveMatch != nil }
	public var canStartNewRealTimeMatch: Bool { GameCenterInterface.instance.isAuthenticated && loadingError == nil }
	
	override private init() {
		super.init()
	}
	
	public func setup() {
		Task {
			if await GameCenterInterface.instance.authenticate() {
				await self.reloadActiveMatches()
			}
		}
	}
	
	public func cancelAutomatching() {
		if !isAutomatching { return }
		
		GKMatchmaker.shared().cancel()
		isAutomatching = false
	}
	
	public func load<Container: RealTimeContainer>(match: GKMatch, container: Container) {
		retainedRealTimeContainer = container
		let active = RealTimeActiveMatch(match: match, container: container, matchManager: self)
		self.realTimeActiveMatch = active
		container.loaded(match: active, with: active.allPlayers)
		isAutomatching = false
	}

	public func load<Container: TurnBasedContainer>(match: GKTurnBasedMatch, container: Container) {
		retainedTurnBasedContainer = container
		replace(match)
		container.clearOut()
		let active = TurnBasedActiveMatch(match: match, container: container, matchManager: self)
		self.turnBasedActiveMatch = active
		container.loaded(match: active)
		lastMatchID  = match.matchID
		isAutomatching = false
	}
	
	public func reloadActiveMatches() async {
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
			print("Failed to reload active matches: \(error.localizedDescription)")
		}
	}
	
	func filterMatches() {
		let sorted = allMatches.sortedByRecency()
		visibleMatches = hideAbortedMatches ? sorted.filter { !$0.wasAborted } : sorted
		activeMatches = sorted.filter { $0.isActive }
	}
	
	@MainActor public func clearRealTimeMatch() {
		realTimeActiveMatch = nil
		retainedRealTimeContainer = nil
	}

	@MainActor public func clearTurnBasedMatch() {
		turnBasedActiveMatch = nil
		retainedTurnBasedContainer = nil
	}
	
	public func turnBasedMatch(withID: String) -> GKTurnBasedMatch? {
		allMatches.first(where: { $0.matchID == withID })
	}
	
	func replace(_ match: GKTurnBasedMatch) {
		if let index = allMatches.firstIndex(where: { $0.matchID == match.matchID }) {
			allMatches[index] = match
		} else {
			allMatches.append(match)
		}
		filterMatches()
	}
	
	public func startAutomatching<Container: RealTimeContainer>(request: GKMatchRequest, container: Container) async throws {
		if isAutomatching { return }
		
		isAutomatching = true
		do {
			let match = try await GKMatchmaker.shared().findMatch(for: request)
			load(match: match, container: container)
		} catch {
			isAutomatching = false
			tourneyLogger.error("Failed to find match: \(error)")
			throw error
		}
	}
	
	public var canRestoreMatch: Bool { lastMatchID != nil }
	public func restore<Container: TurnBasedContainer>(matchID: String? = nil, container: Container) async throws {
		guard turnBasedActiveMatch == nil else { throw MatchManagerError.alreadyHaveActiveMatch }
		guard !loadingMatch else { throw MatchManagerError.restoreInProgress }
		guard let id = matchID ?? lastMatchID else { throw MatchManagerError.missingMatchID }
		loadingMatch = true
		defer { loadingMatch = false }
		let match = try await GKTurnBasedMatch.load(withID: id)
		load(match: match, container: container)
	}
	
	func removeMatch(_ match: GKTurnBasedMatch) {
		if let index = allMatches.firstIndex(where: { $0.matchID == match.matchID }) {
			allMatches.remove(at: index)
			filterMatches()

		}
	}
}

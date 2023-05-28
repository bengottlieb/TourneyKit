//
//  MatchManager.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import GameKit

enum MatchManagerError: Error { case missingMatchID, restoreInProgress, alreadyHaveActiveMatch }

@MainActor public class MatchManager: NSObject, ObservableObject {
	public static let instance = MatchManager()
	
	@Published public var isAutomatching = false
	@Published public var loadingMatch = false
	@Published public var pendingMatchRequest: GKMatchRequest?
	@Published public var activeMatches: [GKTurnBasedMatch] = []
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
		let active = TurnBasedActiveMatch(match: match, game: game, matchManager: self)
		self.turnBasedActiveMatch = active
		game.loaded(match: active)
		lastMatchID  = match.matchID
		isAutomatching = false
	}
	
	public func reloadActiveGames() async throws {
		activeMatches = try await GKTurnBasedMatch.loadMatches()
		print("Loaded \(activeMatches.count) matches")
	}
	
	@MainActor public func clearRealTimeMatch() {
		realTimeActiveMatch = nil
	}
	
	@MainActor public func clearTurnBasedMatch() {
		turnBasedActiveMatch = nil
	}
	
	public func startAutomatching<Game: RealTimeGame>(request: GKMatchRequest, game: Game) async throws {
		if isAutomatching { return }
		
		isAutomatching = true
		do {
			let match = try await GKMatchmaker.shared().findMatch(for: request)
			load(match: match, game: game)
		} catch {
			isAutomatching = false
			print("Failed to find match: \(error)")
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
}

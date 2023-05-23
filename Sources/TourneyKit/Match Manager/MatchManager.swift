//
//  MatchManager.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import GameKit

enum MatchManagerError: Error { case missingMatchID }

@MainActor public class MatchManager: NSObject, ObservableObject {
	public static let instance = MatchManager()
	
	@Published public var isAuthenticated = false
	@Published public var isAutomatching = false
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
	
	public func load<Delegate: RealTimeActiveMatchDelegate>(match: GKMatch, delegate: Delegate) {
		objectWillChange.send()
		let active = RealTimeActiveMatch(match: match, delegate: delegate)
		self.realTimeActiveMatch = active
		delegate.loaded(match: active, with: active.allPlayers)
		isAutomatching = false
	}
	
	public func load<Delegate: TurnBasedActiveMatchDelegate>(match: GKTurnBasedMatch, delegate: Delegate) {
		objectWillChange.send()
		let active = TurnBasedActiveMatch(match: match, delegate: delegate)
		self.turnBasedActiveMatch = active
		delegate.loaded(match: active)
		lastMatchID  = match.matchID
		isAutomatching = false
	}
	
	@MainActor public func clearRealTimeMatch() {
		realTimeActiveMatch = nil
	}
	
	@MainActor public func clearTurnBasedMatch() {
		turnBasedActiveMatch = nil
		lastMatchID = nil
	}
	
	public func startAutomatching<Delegate: RealTimeActiveMatchDelegate>(request: GKMatchRequest, delegate: Delegate) async throws {
		if isAutomatching { return }
		
		isAutomatching = true
		do {
			let match = try await GKMatchmaker.shared().findMatch(for: request)
			load(match: match, delegate: delegate)
		} catch {
			isAutomatching = false
			print("Failed to find match: \(error)")
			throw error
		}
	}
	
	public var canRestoreMatch: Bool { lastMatchID != nil }
	public func restore<Delegate: TurnBasedActiveMatchDelegate>(matchID: String? = nil, delegate: Delegate) async throws {
		guard let id = matchID ?? lastMatchID else { throw MatchManagerError.missingMatchID }
		let match = try await GKTurnBasedMatch.load(withID: id)
		
		load(match: match, delegate: delegate)
	}
	
	var rootViewController: UIViewController? {
		let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		return windowScene?.windows.first?.rootViewController
	}
	
}

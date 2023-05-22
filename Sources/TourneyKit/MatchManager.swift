//
//  MatchManager.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

@MainActor public class MatchManager: NSObject, ObservableObject {
	public static let instance = MatchManager()
	
	@Published public var isAuthenticated = false
	@Published public var isAutomatching = false

	@Published public var realTimeActiveMatch: SomeMatch?
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
		let active = RealTimeActiveMatch(match: match, delegate: delegate)
		self.realTimeActiveMatch = active
		delegate.loaded(match: active, with: active.allPlayers)
		isAutomatching = false
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
	
	var rootViewController: UIViewController? {
		let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		return windowScene?.windows.first?.rootViewController
	}
	
}

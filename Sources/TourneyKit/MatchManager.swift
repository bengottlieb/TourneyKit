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

	@Published public var activeMatch: ActiveMatch?
	public var isInMatch: Bool { activeMatch != nil }
	
	override private init() {
		super.init()
	}
	
	public func cancelAutomatching() {
		if !isAutomatching { return }
		
		GKMatchmaker.shared().cancel()
		isAutomatching = false
	}
	
	public func startAutomatching(request: GKMatchRequest, delegate: ActiveMatchDelegate? = nil) async throws {
		if isAutomatching { return }
		
		isAutomatching = true
		do {
			let match = try await GKMatchmaker.shared().findMatch(for: request)
			let active = ActiveMatch(match: match, delegate: delegate)
			self.activeMatch = active
			delegate?.started(with: match.players, in: active)
			isAutomatching = false
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

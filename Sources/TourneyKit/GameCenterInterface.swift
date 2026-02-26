//
//  File.swift
//
//
//  Created by Ben Gottlieb on 5/23/23.
//

#if canImport(UIKit)
import UIKit
import GameKit
import Achtung

@MainActor @Observable public class GameCenterInterface {
	public static let instance = GameCenterInterface()

	@ObservationIgnored private var authTask: Task<Bool, Never>?
	public var isAuthenticated = false

	public var showingGameCenterAvatar: Bool {
		get { GKAccessPoint.shared.isActive }
		set { GKAccessPoint.shared.isActive = newValue }
	}
	
	public nonisolated static var localPlayerID: String { GKLocalPlayer.local.tourneyKitID }
	public nonisolated static var localPlayerName: String { GKLocalPlayer.local.displayName }

	@discardableResult public func authenticate() async -> Bool {
		if isAuthenticated { return true }
		if let authTask { return await authTask.value }

		let matchManager = RemoteMatchManager.instance
		let newTask = Task { () -> Bool in
			await withCheckedContinuation { continuation in
				var resumed = false
				GKLocalPlayer.local.authenticateHandler = { viewController, error in
					MainActor.assumeIsolated {
						if let viewController {
							self.rootViewController?.present(viewController, animated: true)
							return
						}
						if let error {
							self.isAuthenticated = false
							tourneyLogger.error("GameKit Authentication Error: \(error.localizedDescription).")
							if !resumed { resumed = true; continuation.resume(returning: false) }
							if RemoteMatchManager.instance.showErrors {
								Achtung.show(error, level: .standard, title: "Unable to Connect to Game Center")
							}
							return
						}
						PlayerCache.instance.set(name: GKLocalPlayer.local.displayName, id: GKLocalPlayer.local.tourneyKitID, for: GKLocalPlayer.local)
						GKLocalPlayer.local.register(matchManager)
						GKAccessPoint.shared.location = .topLeading
						GKAccessPoint.shared.showHighlights = true
						GKAccessPoint.shared.isActive = true
						self.isAuthenticated = true
						print("Signed in to GameCenter as \(GKLocalPlayer.local.displayName)")
						Task { await matchManager.reloadActiveMatches() }
						if !resumed { resumed = true; continuation.resume(returning: true) }
					}
				}
			}
		}

		authTask = newTask
		return await newTask.value
	}

	var rootViewController: UIViewController? {
		let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		return windowScene?.keyWindow?.rootViewController
	}
}
#endif

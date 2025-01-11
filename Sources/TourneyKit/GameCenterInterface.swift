//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/23/23.
//

#if canImport(UIKit)
import UIKit
import GameKit
import Combine

public class GameCenterInterface: ObservableObject {
	public static let instance = GameCenterInterface()
	
	var authenticationPublisher: AnyPublisher<Bool, Never>!
	public var isAuthenticated = false
	
	public var showingGameCenterAvatar: Bool {
		get { GKAccessPoint.shared.isActive }
		set { GKAccessPoint.shared.isActive = newValue }
	}
	
	@discardableResult public func authenticate() -> AnyPublisher<Bool, Never> {
		if let authenticationPublisher { return authenticationPublisher }
		let publisher = CurrentValueSubject<Bool, Never>(false)
		
		GKLocalPlayer.local.authenticateHandler = { viewController, error in
			if let viewController = viewController {
				// If the view controller is non-nil, present it to the player so they can
				// perform some necessary action to complete authentication.
				self.rootViewController?.present(viewController, animated: true) { }
				return
			}
			if let error {
				self.isAuthenticated = false
				// If you can’t authenticate the player, disable Game Center features in your game.
				tourneyLogger.error("GameKit Authentication Error: \(error.localizedDescription).")
				return
			}
			
			PlayerCache.instance.set(name: GKLocalPlayer.local.displayName, id: GKLocalPlayer.local.teamPlayerID, for: GKLocalPlayer.local)
			
			// Register for real-time invitations from other players.
			GKLocalPlayer.local.register(MatchManager.instance)
			
			// Add an access point to the interface.
			GKAccessPoint.shared.location = .topLeading
			GKAccessPoint.shared.showHighlights = true
			GKAccessPoint.shared.isActive = true
			self.isAuthenticated = true
			
			Task {
				await MainActor.run {
					Task { try? await MatchManager.instance.reloadActiveGames() }
					self.objectWillChange.send()
					publisher.send(true)
				}
			}
		}
		
		authenticationPublisher = publisher.eraseToAnyPublisher()
		return authenticationPublisher
	}

	var rootViewController: UIViewController? {
		let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		return windowScene?.windows.first?.rootViewController
	}
}
#endif

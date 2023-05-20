//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

extension MatchManager: GKLocalPlayerListener {
	public var showingGameCenterAvatar: Bool {
		get { GKAccessPoint.shared.isActive }
		set { GKAccessPoint.shared.isActive = newValue }
	}
	
	public func authenticate() {
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
				print("Error: \(error.localizedDescription).")
				return
			}
			
			// A value of nil for viewController indicates successful authentication, and you can access
			// local player properties.
			
			// Load the local player's avatar.
			GKLocalPlayer.local.loadPhoto(for: GKPlayer.PhotoSize.small) { image, error in
				if let error {
					// Handle an error if it occurs.
					print("Error: \(error.localizedDescription).")
				}
			}
			
			// Register for real-time invitations from other players.
			GKLocalPlayer.local.register(self)
			
			// Add an access point to the interface.
			GKAccessPoint.shared.location = .topLeading
			GKAccessPoint.shared.showHighlights = true
			GKAccessPoint.shared.isActive = true
			self.isAuthenticated = true
		}
	}
	
}

//
//  PlayerInfoView.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit

public struct PlayerInfoView: View {
	let player: GKPlayer
	
	@State var image: UIImage?
	
	public init(player: GKPlayer?) {
		_image = State(initialValue: PlayerImageCache.instance.cachedImage(for: player, size: .normal))
		self.player = player ?? GKLocalPlayer.local
	}
	
	public var body: some View {
		VStack(alignment: .leading) {
			HStack {
				if let image {
					Image(uiImage: image)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(height: 50)
				}
				Text(player.displayName)
			}
			
			Text("Alias: " + player.alias)
			Text("TourneyKit ID: " + player.playerTag.description)
			Text("Game ID: " + player.gamePlayerID)
			Text("Team ID: " + player.teamPlayerID)
			Text("Guest ID: " + (player.guestIdentifier ?? "--"))
			Text("scopedIDsArePersistent: \(player.scopedIDsArePersistent() ? "Yes" : "No")")
		}
		.task {
			if image == nil {
				image = try? await PlayerImageCache.instance.image(for: player, size: .normal)
			}
		}
	}
}

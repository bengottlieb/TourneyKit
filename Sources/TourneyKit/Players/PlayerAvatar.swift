//
//  PlayerAvatar.swift
//  
//
//  Created by Ben Gottlieb on 5/27/23.
//

import SwiftUI
import GameKit
import CrossPlatformKit

public struct PlayerAvatar: View {
	let player: GKPlayer
	@State var image: UXImage?
	@State var showingDetails = false
	public init(player: GKPlayer) {
		self.player = player
	}

	public var body: some View {
		VStack {
			if let image {
				Image(uxImage: image)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.clipShape(Circle())
			}
			Text(player.displayName)
		}
		.onTapGesture {
			showingDetails.toggle()
		}
		.task {
			if image == nil {
				image = try? await PlayerImageCache.instance.image(for: player, size: .normal)
			}
		}
		.popover(isPresented: $showingDetails) {
			PlayerInfoView(player: player)
		}
	}
}


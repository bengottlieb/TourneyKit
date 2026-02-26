//
//  PlayerLabel.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit
import CrossPlatformKit

public struct PlayerLabel: View {
	let player: GKPlayer
	@State var image: UXImage?
	@State var showingDetails = false
	public init(player: GKPlayer) {
		self.player = player
	}
	
	public var body: some View {
		HStack {
			if let image {
				Image(uxImage: image)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.clipShape(Circle())
					.frame(height: 20)
			}
			Text(player.isLocalPlayer ? "Me" : player.displayName)
		}
		.onTapGesture {
			showingDetails.toggle()
		}
		.task {
			if image == nil {
				image = try? await PlayerImageCache.instance.image(for: player, size: .small)
			}
		}
		.popover(isPresented: $showingDetails) {
			PlayerInfoView(player: player)
		}
	}
}


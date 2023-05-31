//
//  PlayerAvatar.swift
//  
//
//  Created by Ben Gottlieb on 5/27/23.
//

import SwiftUI
import GameKit

public struct PlayerAvatar: View {
	let player: GKPlayer
	@State var image: UIImage?
	@State var showingDetails = false
	public init(player: GKPlayer) {
		_image = State(initialValue: PlayerImageCache.instance.cachedImage(for: player, size: .small))
		self.player = player
	}
	
	public var body: some View {
		VStack {
			if let image {
				Image(uiImage: image)
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


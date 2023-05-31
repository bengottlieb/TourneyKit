//
//  PlayerLabel.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit

public struct PlayerLabel: View {
	let player: GKPlayer
	@State var image: UIImage?
	@State var showingDetails = false
	public init(player: GKPlayer) {
		_image = State(initialValue: PlayerImageCache.instance.cachedImage(for: player, size: .small))
		self.player = player
	}
	
	public var body: some View {
		HStack {
			if let image {
				Image(uiImage: image)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.clipShape(Circle())
					.frame(height: 20)
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


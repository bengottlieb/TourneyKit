//
//  PlayerImageCache.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit
import CrossPlatformKit

public actor PlayerImageCache {
	public static let instance = PlayerImageCache()

	var smallCache: PlayerDictionary<UXImage> = .init()
	var normalCache: PlayerDictionary<UXImage> = .init()

	public func cachedImage(for player: GKPlayer?, size: GKPlayer.PhotoSize) -> UXImage? {
		guard let player else { return nil }
		switch size {
		case .small: return smallCache[player.playerTag]
		case .normal: return normalCache[player.playerTag]
		@unknown default:
			return smallCache[player.playerTag]
		}
	}

	public func image(for optionalPlayer: GKPlayer?, size: GKPlayer.PhotoSize = .small) async throws -> UXImage {
		let player = optionalPlayer ?? GKLocalPlayer.local
		if let cached = cachedImage(for: player, size: size) { return cached }

		let image = try await player.loadPhoto(for: size)

		switch size {
		case .small: smallCache[player.playerTag] = image
		case .normal: normalCache[player.playerTag] = image
		@unknown default: break
		}
		return image
	}
}

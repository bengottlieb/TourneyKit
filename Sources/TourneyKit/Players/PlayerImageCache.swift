//
//  PlayerImageCache.swift
//
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit
import CrossPlatformKit
import JohnnyCache

@MainActor
public class PlayerImageCache {
	public static let instance = PlayerImageCache()

	private let smallCache = JohnnyCache<String, UXImage>()
	private let normalCache = JohnnyCache<String, UXImage>()

	public func image(for optionalPlayer: GKPlayer?, size: GKPlayer.PhotoSize = .small) async throws -> UXImage {
		let player = optionalPlayer ?? GKLocalPlayer.local
		let key = player.teamPlayerID
		let cache = size == .normal ? normalCache : smallCache

		if let cached = cache[key] { return cached }

		let image = try await player.loadPhoto(for: size)
		cache[key] = image
		return image
	}
}

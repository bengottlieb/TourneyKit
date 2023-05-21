//
//  PlayerImageCache.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit

public class PlayerImageCache {
	public static let instance = PlayerImageCache()
	
	var smallCache: [String: UIImage] = [:]
	var normalCache: [String: UIImage] = [:]
	
	public func cachedImage(for player: GKPlayer, size: GKPlayer.PhotoSize) -> UIImage? {
		switch size {
		case .small: return smallCache[player.teamPlayerID]
		case .normal: return normalCache[player.teamPlayerID]
		@unknown default:
			return smallCache[player.teamPlayerID]
		}
	}
	
	public func image(for player: GKPlayer, size: GKPlayer.PhotoSize = .small) async throws -> UIImage {
		if let cached = cachedImage(for: player, size: size) { return cached }
		let image = try await player.loadPhoto(for: size)
		
		switch size {
		case .small: smallCache[player.teamPlayerID] = image
		case .normal: normalCache[player.teamPlayerID] = image
		@unknown default: break
		}
		return image
	}
}

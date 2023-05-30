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
		guard let id = player.tourneyKitID else { return nil }
		switch size {
		case .small: return smallCache[id]
		case .normal: return normalCache[id]
		@unknown default:
			return smallCache[id]
		}
	}
	
	public func image(for player: GKPlayer, size: GKPlayer.PhotoSize = .small) async throws -> UIImage {
		if let cached = cachedImage(for: player, size: size) { return cached }

		let image = try await player.loadPhoto(for: size)
		
		if let id = player.tourneyKitID {
			switch size {
			case .small: smallCache[id] = image
			case .normal: normalCache[id] = image
			@unknown default: break
			}
		}
		return image
	}
}

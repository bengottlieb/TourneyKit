//
//  PlayerDictionary.swift
//
//
//  Created by Ben Gottlieb on 6/7/23.
//

import Foundation
import GameKit

public struct PlayerDictionary<Content> {
	struct TaggedContent {
		let tag: GKPlayer.PlayerTag
		var content: Content
	}
	
	public init() { }
	
	public var values: [Content] { contents.map { $0.content }}
	var contents: [TaggedContent] = []
	
	public subscript(tag: GKPlayer.PlayerTag?) -> Content? {
		get {
			guard let index = index(of: tag) else { return nil }
			return contents[index].content
		}
		set {
			guard let tag else { return }
			if let index = index(of: tag) {
				if let newValue {
					contents[index].content = newValue
				} else {
					contents.remove(at: index)
				}
			} else if let newValue {
				contents.append(.init(tag: tag, content: newValue))
			}
		}
	}
	
	func index(of tag: GKPlayer.PlayerTag?) -> Int? {
		contents.map({ $0.tag }).firstIndex(tag: tag)
	}
	
	public subscript(player: GKPlayer?) -> Content? {
		get { self[player?.playerTag] }
		set { self[player?.playerTag] = newValue }
	}
}

extension PlayerDictionary: Codable where Content: Codable {
	
}

extension PlayerDictionary.TaggedContent: Codable where Content: Codable { }

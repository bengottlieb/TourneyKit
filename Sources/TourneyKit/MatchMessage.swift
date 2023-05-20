//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import Foundation
import GameKit

public protocol MatchMessage: Codable { }

struct RawMessage: MatchMessage {
	enum Kind: String, Codable { case start, end, state, update }
	let kind: Kind
}

public struct MessageMatchStart: MatchMessage {
	var kind = RawMessage.Kind.start
	public init() { }
}

public struct MessageMatchEnd: MatchMessage {
	var kind = RawMessage.Kind.end
	public init() { }
}

public struct MessageMatchState<Payload: Codable>: MatchMessage {
	var kind = RawMessage.Kind.state
	var payload: Payload
	public init(_ payload: Payload) {
		self.payload = payload
	}
}

public struct MessageMatchUpdate<Payload: Codable>: MatchMessage {
	var kind = RawMessage.Kind.update
	var payload: Payload
	public init(_ payload: Payload) {
		self.payload = payload
	}
}


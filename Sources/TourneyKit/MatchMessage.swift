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
	enum Kind: String, Codable { case phaseChange, playerInfo, state, update }
	let kind: Kind
}

public struct MessageMatchPhaseChange: MatchMessage {
	var kind = RawMessage.Kind.phaseChange
	var phase: ActiveMatchPhase
	public init(_ phase: ActiveMatchPhase) { self.phase = phase }
}

public struct MessagePlayerInfo: MatchMessage {
	var kind = RawMessage.Kind.playerInfo
	var name: String
	let id: String
	public init(_ player: GKPlayer) { name = player.displayName; id = player.tourneyKitID }
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


//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import Foundation
import GameKit

extension RealTimeActiveMatch {
	func handleIncoming(data: Data, from player: GKPlayer) {
		guard let raw = try? JSONDecoder().decode(RawMessage.self, from: data) else {
			game?.didReceive(data: data, from: player)
			return
		}

		switch raw.kind {
		case .phaseChange:
			if let full = try? JSONDecoder().decode(MessageMatchPhaseChange.self, from: data) {
				TKLogger.instance.log(.matchPhaseChange(match, full.phase))
				handleRemotePhaseChange(to: full.phase)
			}

		case .state:
			if let full = try? JSONDecoder().decode(MessageMatchState<Game.MatchState>.self, from: data) {
				TKLogger.instance.log(.matchStateReceived(match, data))
				game?.matchStateChanged(to: full.payload)
				recentlyReceivedData.append(full)
				if recentlyReceivedData.count > recentDataDepth { recentlyReceivedData.removeFirst() }
			}

		case .update:
			if let full = try? JSONDecoder().decode(MessageMatchState<Game.MatchUpdate>.self, from: data) {
				TKLogger.instance.log(.matchUpateReceived(match, data))
				game?.matchUpdated(with: full.payload)
				recentlyReceivedData.append(full)
				if recentlyReceivedData.count > recentDataDepth { recentlyReceivedData.removeFirst() }
			}

		case .playerInfo:
			if let full = try? JSONDecoder().decode(MessagePlayerInfo.self, from: data) {
				TKLogger.instance.log(.playerInfoReceived(match, player, full.name, full.id))
				PlayerCache.instance.set(name: full.name, id: full.id, for: player)
			}
		}
	}
	
	public func sendUpdate(_ update: Game.MatchUpdate, reliably: Bool = true) throws {
		try send(message: MessageMatchUpdate(update), reliably: reliably)
	}
	
	public func sendState(_ state: Game.MatchState, reliably: Bool = true) throws {
		try send(message: MessageMatchState(state), reliably: reliably)
	}
	
	func send<Message: MatchMessage>(message: Message, reliably: Bool = true) throws {
		let data = try JSONEncoder().encode(message)
		do {
			try send(data: data, reliably: reliably)
		} catch {
			recentErrors.append(error)
			throw error
		}
	}
	
}

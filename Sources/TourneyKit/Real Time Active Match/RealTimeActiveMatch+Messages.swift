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
		do {
			let raw = try JSONDecoder().decode(RawMessage.self, from: data)
			
			switch raw.kind {
			case .phaseChange:
				if let full = try? JSONDecoder().decode(MessageMatchPhaseChange.self, from: data) {
					TKLogger.instance.log(.matchPhaseChange(match, full.phase))
					handleRemotePhaseChange(to: full.phase)
				}
				
			case .state:
				if let full = try? JSONDecoder().decode(MessageMatchState<Game.GameState>.self, from: data) {
					TKLogger.instance.log(.matchStateReceived(match, data))
					game?.matchStateChanged(to: full.payload)
				}
				
			case .update:
				if let full = try? JSONDecoder().decode(MessageMatchState<Game.GameUpdate>.self, from: data) {
					TKLogger.instance.log(.matchUpateReceived(match, data))
					game?.matchUpdated(with: full.payload)
				}
				
			case .playerInfo:
				if let full = try? JSONDecoder().decode(MessagePlayerInfo.self, from: data) {
					TKLogger.instance.log(.playerInfoReceived(match, player, full.name, full.id))
					PlayerCache.instance.set(name: full.name, id: full.id, for: player)
				}
			}
		} catch {
			tourneyLogger.error("Failed to process a message: \(String(data: data, encoding: .utf8) ?? "--")")
			let error = error
			Task { @MainActor in self.recentErrors.append(error) }
		}
	}
	
	public func sendUpdate(_ update: Game.GameUpdate, reliably: Bool = true) throws {
		try send(message: MessageMatchUpdate(update), reliably: reliably)
	}
	
	public func sendState(_ state: Game.GameState, reliably: Bool = true) throws {
		try send(message: MessageMatchState(state), reliably: reliably)
	}
	
	func send<Message: MatchMessage>(message: Message, reliably: Bool = true) throws {
		let data = try JSONEncoder().encode(message)
		do {
			try send(data: data, reliably: reliably)
		} catch {
			let error = error
			Task { @MainActor in self.recentErrors.append(error) }
			throw error
		}
	}
	
}

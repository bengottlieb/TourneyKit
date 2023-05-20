//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import Foundation
import GameKit

extension ActiveMatch {
	func handleIncoming(data: Data, from player: GKPlayer) {
		do {
			let raw = try JSONDecoder().decode(RawMessage.self, from: data)
			
			switch raw.kind {
			case .phaseChange:
				if let full = try? JSONDecoder().decode(MessageMatchPhaseChange.self, from: data) {
					handleRemotePhaseChange(to: full.phase)
				}
				
			case .state:
				if let full = try? JSONDecoder().decode(MessageMatchState<Delegate.GameState>.self, from: data) {
					delegate?.matchStateChanged(to: full.payload)
				}
				
			case .update:
				if let full = try? JSONDecoder().decode(MessageMatchState<Delegate.GameUpdate>.self, from: data) {
					delegate?.matchUpdated(with: full.payload)
				}
			}
		} catch {
			recentErrors.append(error)
			print("Failed to process a message: \(String(data: data, encoding: .utf8) ?? "--")")
		}
	}
	
	public func sendUpdate(_ update: Delegate.GameUpdate, reliably: Bool = true) throws {
		try send(message: MessageMatchUpdate(update), reliably: reliably)
	}
	
	public func sendState(_ state: Delegate.GameState, reliably: Bool = true) throws {
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

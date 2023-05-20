//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

public protocol ActiveMatchDelegate {
	func didReceive(data: Data, from player: GKPlayer, in: ActiveMatch)
	func started(with players: [GKPlayer], in: ActiveMatch)
	func playersChanged(to players: [GKPlayer], in: ActiveMatch)
	
	func started(match: ActiveMatch)
	func ended(match: ActiveMatch)
}

@MainActor public class ActiveMatch: NSObject, ObservableObject {
	public let match: GKMatch
	public var delegate: ActiveMatchDelegate?
	@Published public var recentlyReceivedData: [MatchMessage] = []
	var recentDataDepth = 5
	@Published public var recentErrors: [Error] = []
	
	init(match: GKMatch, delegate: ActiveMatchDelegate?) {
		self.match = match
		super.init()
		
		self.delegate = delegate
		match.delegate = self
	}
	
	public func endMatch() {
		try? send(message: MessageMatchEnd())
		
		if MatchManager.instance.activeMatch == self {
			MatchManager.instance.activeMatch = nil
		}
		match.disconnect()
	}
	
	public func send<Message: MatchMessage>(message: Message, reliably: Bool = true) throws {
		let data = try JSONEncoder().encode(message)
		do {
			try send(data: data, reliably: reliably)
		} catch {
			recentErrors.append(error)
			throw error
		}
	}
	
	func send(data: Data, reliably: Bool = true) throws {
		try match.sendData(toAllPlayers: data, with: reliably ? .reliable : .unreliable)
	}
}

extension ActiveMatch: GKMatchDelegate {
	public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
		Task {
			await MainActor.run {
				self.delegate?.playersChanged(to: match.players, in: self)
			}
		}
	}
	
	public func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
		 return true
	}

	public func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
		do {
			let raw = try JSONDecoder().decode(RawMessage.self, from: data)
			
			switch raw.kind {
			case .start: delegate?.started(match: self)
			case .end: delegate?.ended(match: self)
			default: break
			}
		} catch {
			recentErrors.append(error)
			print("Failed to process a message: \(String(data: data, encoding: .utf8) ?? "--")")
		}
//		Task {
//			await MainActor.run {
//				self.objectWillChange.send()
//				self.recentlyReceivedData.append(ReceivedData(data: data))
//				if self.recentlyReceivedData.count > self.recentDataDepth { self.recentlyReceivedData.remove(at: 0) }
//				self.delegate?.didReceive(data: data, from: player, in: self)
//			}
//		}
	}
}

extension ActiveMatch {
	public struct ReceivedData {
		let receivedAt = Date()
		let data: Data
	}
}

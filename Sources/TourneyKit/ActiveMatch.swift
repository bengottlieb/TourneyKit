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
}

public class ActiveMatch: NSObject, ObservableObject {
	public let match: GKMatch
	public var delegate: ActiveMatchDelegate?
	public var recentlyReceivedData: [ReceivedData] = []
	public var recentDataDepth = 5
	
	init(match: GKMatch, delegate: ActiveMatchDelegate?) {
		self.match = match
		super.init()
		
		self.delegate = delegate
		match.delegate = self
	}
	
	public func send(data: Data, reliably: Bool = true) throws {
		try match.sendData(toAllPlayers: data, with: reliably ? .reliable : .unreliable)

	}
}

extension ActiveMatch: GKMatchDelegate {
	public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
		print("player: \(player.displayName), did change to: \(state)")
	}
	
	public func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
		 return true
	}

	public func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
		Task {
			await MainActor.run {
				self.objectWillChange.send()
				self.recentlyReceivedData.append(ReceivedData(data: data))
				if self.recentlyReceivedData.count > self.recentDataDepth { self.recentlyReceivedData.remove(at: 0) }
				self.delegate?.didReceive(data: data, from: player, in: self)
			}
		}
	}
}

extension ActiveMatch {
	public struct ReceivedData {
		let receivedAt = Date()
		let data: Data
	}
}

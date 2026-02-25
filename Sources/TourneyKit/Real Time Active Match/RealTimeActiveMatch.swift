//
//  File.swift
//
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

@MainActor @Observable public class RealTimeActiveMatch<Container: RealTimeContainer>: NSObject, @preconcurrency GKMatchDelegate, SomeGameKitMatch {
	public let match: GKMatch
	@ObservationIgnored public weak var container: Container?
	@ObservationIgnored let manager: RemoteMatchManager
	public private(set) var phase: ActiveMatchPhase = .loading
	public var recentlyReceivedData: [any MatchMessage] = []
	@ObservationIgnored public var recentDataDepth = 5
	public var recentErrors: [any Error] = []
	public var allPlayers: [GKPlayer] { [GKLocalPlayer.local] + match.players }
	public var parentContainer: AnyObject? { container }

	init(match: GKMatch, container: Container?, matchManager: RemoteMatchManager) {
		self.match = match
		self.manager = matchManager
		super.init()

		self.container = container
		match.delegate = self
	}

	public func startMatch() {
		self.phase = .playing
		sendPhaseChangedMessage()
	}

	func sendPlayerInfo(for player: GKPlayer = GKLocalPlayer.local) {
		try? send(message: MessagePlayerInfo(player), reliably: true)
	}

	func sendPhaseChangedMessage() {
		try? send(message: MessageMatchPhaseChange(phase))
	}

	func terminateLocally() {
		if manager.realTimeActiveMatch === self {
			manager.clearRealTimeMatch()
		}
		match.disconnect()
	}

	public var turnBasedMatch: GKTurnBasedMatch? { nil }
	public var realTimeMatch: GKMatch? { match }

	public func endMatch() {
		phase = .ended
		sendPhaseChangedMessage()
		terminateLocally()
	}

	public func terminate() {
		terminateLocally()
	}

	func send(data: Data, reliably: Bool = true) throws {
		try match.sendData(toAllPlayers: data, with: reliably ? .reliable : .unreliable)
	}

	public func match(_ match: GKMatch, didFailWithError error: Error?) {
		if let error {
			tourneyLogger.error("Match failed: \(error)")
			recentErrors.append(error)
			container?.matchFailed(withError: error)
		}
		terminateLocally()
	}

	public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
		TKLogger.instance.log(.matchChangedPlayerState(match, player, state))
		switch state {
		case .connected:
			sendPlayerInfo()

		default: break
		}
		self.container?.playersChanged(to: allPlayers)
	}

	public func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
		TKLogger.instance.log(.matchShouldReinviteDisconnectedPlayer(match, player))
		tourneyLogger.info("shouldReinviteDisconnectedPlayer")
		return true
	}

	public func match(_ match: GKMatch, didReceive data: Data, forRecipient recipient: GKPlayer, fromRemotePlayer player: GKPlayer) {
		TKLogger.instance.log(.matchReceivedData(match, player, data))
		handleIncoming(data: data, from: player)
	}

	func handleRemotePhaseChange(to newPhase: ActiveMatchPhase) {
		if self.phase == newPhase { return }
		self.phase = newPhase
		container?.matchPhaseChanged(to: newPhase)
	}
}

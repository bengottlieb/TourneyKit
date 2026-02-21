//
//  File.swift
//
//
//  Created by Ben Gottlieb on 5/19/23.
//

import Foundation
import GameKit

@MainActor @Observable public class RealTimeActiveMatch<Game: RealTimeGame>: NSObject, @preconcurrency GKMatchDelegate, SomeMatch {
	public let match: GKMatch
	@ObservationIgnored public weak var game: Game?
	@ObservationIgnored let manager: MatchManager
	public private(set) var phase: ActiveMatchPhase = .loading
	public var recentlyReceivedData: [any MatchMessage] = []
	@ObservationIgnored var recentDataDepth = 5
	public var recentErrors: [any Error] = []
	public var allPlayers: [GKPlayer] { [GKLocalPlayer.local] + match.players }
	public var parentGame: AnyObject? { game }

	init(match: GKMatch, game: Game?, matchManager: MatchManager) {
		self.match = match
		self.manager = matchManager
		super.init()

		self.game = game
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
			game?.matchFailed(withError: error)
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
		self.game?.playersChanged(to: allPlayers)
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
		game?.matchPhaseChanged(to: newPhase)
	}
}

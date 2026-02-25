//
//  RemoteMatchManager+Conformance.swift
//
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit

extension RemoteMatchManager: @preconcurrency GKLocalPlayerListener { }

extension RemoteMatchManager /* GKInviteEventListener */ {
	public func player(_ player: GKPlayer, didAccept invite: GKInvite) {
		TKLogger.instance.log(.playerAccept(player, invite))
	}
	public func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer])  { TKLogger.instance.log(.playerRequestMatch(recipientPlayers)) }
}

extension RemoteMatchManager /* GKSavedGameListener */ {
	public func player(_ player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) { TKLogger.instance.log(.playerDidModifySavedGame(savedGame)) }
	public func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) { TKLogger.instance.log(.playerHasConflictingSavedGames(player, savedGames)) }
}

extension RemoteMatchManager /* GKTurnBasedEventListener */ {
	
	public func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {
		TKLogger.instance.log(.didRequestMatch(playersToInvite))
		guard let containerType = turnBasedContainerClass else {
			tourneyLogger.error("Received a Match Request from GameCenter, but no turnBasedContainerClass is set in the RemoteMatchManager. Please set this if you want to support these messages.")
			return
		}
		
		let request = containerType.defaultRequest
		request.recipients = playersToInvite
		self.pendingMatchRequest = request
	}
	
	public func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
		TKLogger.instance.log(.receivedTurnEvent(player, match))
		replace(match)
		if match.matchID == turnBasedActiveMatch?.turnBasedMatch?.matchID { turnBasedActiveMatch?.receivedTurn(for: player, didBecomeActive: didBecomeActive, in: match) }
	}
	
	public func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
		TKLogger.instance.log(.matchEnded(match))
		replace(match)
		if match.matchID == turnBasedActiveMatch?.turnBasedMatch?.matchID { turnBasedActiveMatch?.matchEnded(for: player, in: match) }
	}
	
	public func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
		TKLogger.instance.log(.receivedExchangeRequest(exchange, match))
		replace(match)
		if match.matchID == turnBasedActiveMatch?.turnBasedMatch?.matchID { turnBasedActiveMatch?.player(player, receivedExchangeRequest: exchange, in: match) }
	}
	
	public func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
		TKLogger.instance.log(.receivedExchangeCancellation(exchange, match))
		replace(match)
		if match.matchID == turnBasedActiveMatch?.turnBasedMatch?.matchID { turnBasedActiveMatch?.player(player, receivedExchangeCancellation: exchange, in: match) }
	}
	
	public func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
		TKLogger.instance.log(.receivedExchangeReplies(replies, exchange, match))
		replace(match)
		if match.matchID == turnBasedActiveMatch?.turnBasedMatch?.matchID { turnBasedActiveMatch?.player(player, receivedExchangeReplies: replies, forCompletedExchange: exchange, in: match) }

	}
	
	public func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
		TKLogger.instance.log(.wantsToQuitMatch(player, match))
		replace(match)
		if match.matchID == turnBasedActiveMatch?.turnBasedMatch?.matchID { turnBasedActiveMatch?.quitRequest(from: player, in: match) }

	}
	
}

extension RemoteMatchManager /* GKChallengeListener */ {
	public func player(_ player: GKPlayer, wantsToPlay challenge: GKChallenge) { TKLogger.instance.log(.playerWantsToPlay(player, challenge)) }
	public func player(_ player: GKPlayer, didReceive challenge: GKChallenge) { TKLogger.instance.log(.playerDidReceiveChallenge(player, challenge)) }
	public func player(_ player: GKPlayer, didComplete challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) { TKLogger.instance.log(.playerDidCompleteChallenge(player, challenge)) }
	public func player(_ player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) { TKLogger.instance.log(.playerIssuedChallengeWasCompleted(player, challenge, friendPlayer)) }
	
}

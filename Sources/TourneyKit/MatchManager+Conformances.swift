//
//  MatchManager+Conformance.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit



extension MatchManager /* GKInviteEventListener */ {
	public func player(_ player: GKPlayer, didAccept invite: GKInvite) {
		Logger.instance.log(.playerAccept(player, invite))
	}
	public func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer])  { Logger.instance.log(.playerRequestMatch(recipientPlayers)) }
}

extension MatchManager /* GKSavedGameListener */ {
	public func player(_ player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) { Logger.instance.log(.playerDidModifySavedGame(savedGame)) }
	public func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) { Logger.instance.log(.playerHasConflictingSavedGames(player, savedGames)) }
}

extension MatchManager /* GKTurnBasedEventListener */ {
	
	public func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) { Logger.instance.log(.didRequestMatch(playersToInvite)) }
	public func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) { Logger.instance.log(.receivedTurnEvent(player, match)) }
	public func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) { Logger.instance.log(.matchEnded(match)) }
	public func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) { Logger.instance.log(.receivedExchangeRequest(exchange, match)) }
	public func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) { Logger.instance.log(.receivedExchangeCancellation(exchange, match)) }
	public func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) { Logger.instance.log(.receivedExchangeReplies(replies, exchange, match)) }
	public func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) { Logger.instance.log(.wantsToQuitMatch(player, match)) }
}

extension MatchManager /* GKChallengeListener */ {
	public func player(_ player: GKPlayer, wantsToPlay challenge: GKChallenge) { Logger.instance.log(.playerWantsToPlay(player, challenge)) }
	public func player(_ player: GKPlayer, didReceive challenge: GKChallenge) { Logger.instance.log(.playerDidReceiveChallenge(player, challenge)) }
	public func player(_ player: GKPlayer, didComplete challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) { Logger.instance.log(.playerDidCompleteChallenge(player, challenge)) }
	public func player(_ player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) { Logger.instance.log(.playerIssuedChallengeWasCompleted(player, challenge, friendPlayer)) }
	
}

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
		TourneyKitLogger.instance.log(.playerAccept(player, invite))
	}
	public func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer])  { TourneyKitLogger.instance.log(.playerRequestMatch(recipientPlayers)) }
}

extension MatchManager /* GKSavedGameListener */ {
	public func player(_ player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) { TourneyKitLogger.instance.log(.playerDidModifySavedGame(savedGame)) }
	public func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) { TourneyKitLogger.instance.log(.playerHasConflictingSavedGames(player, savedGames)) }
}

extension MatchManager /* GKTurnBasedEventListener */ {
	
	public func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) { TourneyKitLogger.instance.log(.didRequestMatch(playersToInvite)) }
	public func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) { TourneyKitLogger.instance.log(.receivedTurnEvent(player, match)) }
	public func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) { TourneyKitLogger.instance.log(.matchEnded(match)) }
	public func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) { TourneyKitLogger.instance.log(.receivedExchangeRequest(exchange, match)) }
	public func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) { TourneyKitLogger.instance.log(.receivedExchangeCancellation(exchange, match)) }
	public func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) { TourneyKitLogger.instance.log(.receivedExchangeReplies(replies, exchange, match)) }
	public func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) { TourneyKitLogger.instance.log(.wantsToQuitMatch(player, match)) }
}

extension MatchManager /* GKChallengeListener */ {
	public func player(_ player: GKPlayer, wantsToPlay challenge: GKChallenge) { TourneyKitLogger.instance.log(.playerWantsToPlay(player, challenge)) }
	public func player(_ player: GKPlayer, didReceive challenge: GKChallenge) { TourneyKitLogger.instance.log(.playerDidReceiveChallenge(player, challenge)) }
	public func player(_ player: GKPlayer, didComplete challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) { TourneyKitLogger.instance.log(.playerDidCompleteChallenge(player, challenge)) }
	public func player(_ player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) { TourneyKitLogger.instance.log(.playerIssuedChallengeWasCompleted(player, challenge, friendPlayer)) }
	
}

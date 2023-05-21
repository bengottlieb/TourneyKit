//
//  TourneyKitLogger.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit

public class TourneyKitLogger: ObservableObject {
	public static let instance = TourneyKitLogger()
	
	func log(_ message: Message) { print("🎮 \(message.description)") }
	
	enum Message: CustomStringConvertible {
		case matchReceivedData(GKMatch, GKPlayer, Data), matchChangedPlayerState(GKMatch, GKPlayer, GKPlayerConnectionState), matchFailedWithError(Error), matchShouldReinviteDisconnectedPlayer(GKMatch, GKPlayer)
		
		case playerAccept(GKPlayer, GKInvite), playerRequestMatch([GKPlayer])
		
		case playerDidModifySavedGame(GKSavedGame), playerHasConflictingSavedGames(GKPlayer, [GKSavedGame])
		case playerWantsToPlay(GKPlayer, GKChallenge), playerDidReceiveChallenge(GKPlayer, GKChallenge), playerDidCompleteChallenge(GKPlayer, GKChallenge), playerIssuedChallengeWasCompleted(GKPlayer, GKChallenge, GKPlayer)
		case didRequestMatch([GKPlayer]), receivedTurnEvent(GKPlayer, GKTurnBasedMatch), matchEnded(GKTurnBasedMatch), receivedExchangeRequest(GKTurnBasedExchange, GKTurnBasedMatch), receivedExchangeCancellation(GKTurnBasedExchange, GKTurnBasedMatch), receivedExchangeReplies([GKTurnBasedExchangeReply], GKTurnBasedExchange, GKTurnBasedMatch), wantsToQuitMatch(GKPlayer, GKTurnBasedMatch)
		
		var description: String {
			switch self {
				
			case .matchReceivedData(_, let player, _):
				return "matchReceivedData from \(player.displayName)"
			case .matchChangedPlayerState(_, let player, let state):
				return "matchChangedPlayerState from \(player.displayName), \(state.rawValue)"
			case .matchFailedWithError(let error):
				return "matchFailedWithError \(error.localizedDescription)"
			case .matchShouldReinviteDisconnectedPlayer(_, let player):
				return "matchShouldReinviteDisconnectedPlayer \(player.displayName)"
			case .playerAccept(let player, _):
				return "player accepted \(player.displayName)"
			case .playerRequestMatch(let players):
				return "playerRequestMatch \(players.map { $0.displayName }.joined(separator: ", "))"
			case .playerDidModifySavedGame(_):
				return "playerDidModifySavedGame"
			case .playerHasConflictingSavedGames(_, _):
				return "playerHasConflictingSavedGames"
			case .playerWantsToPlay(_, _):
				return "playerWantsToPlay"
			case .playerDidReceiveChallenge(_, _):
				return "playerDidReceiveChallenge"
			case .playerDidCompleteChallenge(_, _):
				return "playerDidCompleteChallenge"
			case .playerIssuedChallengeWasCompleted(_, _, _):
				return "playerIssuedChallengeWasCompleted"
			case .didRequestMatch(_):
				return "didRequestMatch"
			case .receivedTurnEvent(_, _):
				return "receivedTurnEvent"
			case .matchEnded(_):
				return "matchEnded"
			case .receivedExchangeRequest(_, _):
				return "receivedExchangeRequest"
			case .receivedExchangeCancellation(_, _):
				return "receivedExchangeCancellation"
			case .receivedExchangeReplies(_, _, _):
				return "receivedExchangeReplies"
			case .wantsToQuitMatch(_, _):
				return "wantsToQuitMatch"
			}
		}
	}
}

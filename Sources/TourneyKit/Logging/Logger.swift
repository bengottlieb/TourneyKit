//
//  Logger.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit

extension GKPlayer {
	var shortDescription: String {
		var result = displayName
		if teamPlayerID.contains(":") { result += ", " + teamPlayerID }
		if gamePlayerID.contains(":") { result += ", " + gamePlayerID }
		if let id = tourneyKitID { result += ", " + id }
		return result
	}
}

public class Logger: ObservableObject {
	public static let instance = Logger()
	var lastMessageAt = Date()
	
	#if targetEnvironment(simulator)
		public var logMessages = true
	#else
		public var logMessages = true
	#endif
	public var logDepth = 20
	
	var messages: [Message] = []
	
	func log(_ message: Message) {
		messages.append(message)
		while messages.count > logDepth { messages.remove(at: 0) }
		if logMessages { print("🎮 \(message.description)") }
		lastMessageAt = Date()
		DispatchQueue.main.async { self.objectWillChange.send() }
	}
	
	enum Message: CustomStringConvertible {
		case matchReceivedData(GKMatch, GKPlayer, Data), matchChangedPlayerState(GKMatch, GKPlayer, GKPlayerConnectionState), matchFailedWithError(Error), matchShouldReinviteDisconnectedPlayer(GKMatch, GKPlayer)
		
		case playerAccept(GKPlayer, GKInvite), playerRequestMatch([GKPlayer])
		
		case playerDidModifySavedGame(GKSavedGame), playerHasConflictingSavedGames(GKPlayer, [GKSavedGame])
		case playerWantsToPlay(GKPlayer, GKChallenge), playerDidReceiveChallenge(GKPlayer, GKChallenge), playerDidCompleteChallenge(GKPlayer, GKChallenge), playerIssuedChallengeWasCompleted(GKPlayer, GKChallenge, GKPlayer)
		case didRequestMatch([GKPlayer]), receivedTurnEvent(GKPlayer, GKTurnBasedMatch), matchEnded(GKTurnBasedMatch), receivedExchangeRequest(GKTurnBasedExchange, GKTurnBasedMatch), receivedExchangeCancellation(GKTurnBasedExchange, GKTurnBasedMatch), receivedExchangeReplies([GKTurnBasedExchangeReply], GKTurnBasedExchange, GKTurnBasedMatch), wantsToQuitMatch(GKPlayer, GKTurnBasedMatch)
		case matchPhaseChange(GKMatch, ActiveMatchPhase), matchStateReceived(GKMatch, Data), matchUpateReceived(GKMatch, Data), playerInfoReceived(GKMatch, GKPlayer, String, String)
		
		var description: String {
			switch self {
				
			case .matchReceivedData(_, let player, let data):
				return "matchReceivedData \(data.count) bytes from \(player.shortDescription)"
			case .matchChangedPlayerState(_, let player, let state):
				return "matchChangedPlayerState for \(player.shortDescription): \(state)"
			case .matchFailedWithError(let error):
				return "matchFailedWithError \(error.localizedDescription)"
			case .matchShouldReinviteDisconnectedPlayer(_, let player):
				return "matchShouldReinviteDisconnectedPlayer \(player.shortDescription)"
			case .playerAccept(let player, _):
				return "player accepted \(player.shortDescription)"
			case .playerRequestMatch(let players):
				return "playerRequestMatch \(players.map { $0.shortDescription }.joined(separator: ", "))"
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
				
			case .matchPhaseChange(_, let phase):
				return "matchPhaseChanged to \(phase)"
			case .matchStateReceived(_, let data):
				return "matchStateReceived: \(data.count) bytes"
			case .matchUpateReceived(_, let data):
				return "matchUpateReceived: \(data.count) bytes"
			case .playerInfoReceived(_, _, let name, let id):
				return "playerInfoReceived: \(name), \(id)"
			}
		}
	}
}

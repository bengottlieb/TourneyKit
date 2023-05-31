//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 5/30/23.
//

import SwiftUI
import GameKit

public struct TurnBasedMatchInfoView: View {
	let match: GKTurnBasedMatch
	
	public init(match: GKTurnBasedMatch) {
		self.match = match
	}
	
	public var body: some View {
		VStack(alignment: .leading) {
			Text("ID: \(match.matchID)")
			Text("Created: \(match.creationDate.formatted())")
			Text("Status: \(match.status.description)")
			Text("Current Player ID: \(match.currentParticipant?.player?.tourneyKitID ?? "--")")
			if let name = match.currentParticipant?.player?.displayName {
				HStack {
					Text("\(name)")
						.bold()
					if match.isLocalPlayersTurn { Text("(Me)").bold() }
				}
			}
			
			Text("Data: \(match.matchData?.count ?? 0) bytes")
			Text("Message: \(match.message ?? "--")")
			ForEach(match.participants.indices, id: \.self) { idx in
				let part = match.participants[idx]
				ParticipantDetails(participant: part)
				Divider()
			}
		}
	}
	
	struct ParticipantDetails: View {
		let participant: GKTurnBasedParticipant
		
		var body: some View {
			VStack(alignment: .leading) {
				HStack {
					if let player = participant.player {
						PlayerLabel(player: player)
						if player == GKLocalPlayer.local { Text("Me") }
					}
					Text("Last Turn: \(participant.lastTurnDate?.formatted() ?? "--")")
				}
				Text("ID: ") + Text(participant.player?.tourneyKitID ?? "").bold()
				HStack {
					Text("Outcome: ") + Text("\(participant.matchOutcome.description)")
							.bold()
					Text("Status: ") + Text("\(participant.status.description)")						.bold()
				}
				if let timeout = participant.timeoutDate {
					Text("Timeout: \(timeout.formatted())")
				}
			}
		}
	}
}

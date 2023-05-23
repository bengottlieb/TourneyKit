//
//  TurnBasedGameView.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/22/23.
//

import SwiftUI
import TourneyKit

struct TurnBasedGameView: View {
	@ObservedObject var game: TurnBasedGameExample
	@ObservedObject var mgr = MatchManager.instance
	
	var body: some View {
		VStack {
			ZStack {
				Text("TTT Game")
				HStack {
					Spacer()
					Button("Done") { mgr.turnBasedActiveMatch = nil }
						.padding()
				}
			}

			Spacer()
			
			Button("End Turn") {
				Task { await game.endTurn() }
			}
			.disabled(game.match?.isLocalPlayersTurn != true)
			
		}
	}
}

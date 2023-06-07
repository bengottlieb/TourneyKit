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
	@EnvironmentObject var mgr: MatchManager
	@State var isReloading = false
	
	func reloadMatch() {
		isReloading = true
		Task {
			do {
				try await game.match?.reloadMatch()
			} catch {
				appLogger.info("Failed to reload match: \(error)")
			}
			isReloading = false
		}
	}
	
	var body: some View {
		VStack {
			ZStack {
				Text("TTT Game -\(game.match?.status.description ?? "##")")
				HStack {
					Spacer()
					Button("Done") { mgr.clearTurnBasedMatch() }
						.padding()
				}
			}

			Spacer()
			
			HStack {
				Button("Resign") {
					Task {
						do {
							try await game.match?.endGame(withOutcome: .lost)
							game.objectWillChange.send()
						} catch {
							appLogger.info("Failed to resign: \(error)")
						}
					}
				}
				.disabled(game.match?.isLocalPlayerPlaying == false)
				.padding()
				
				Spacer()

				Button("End Turn") {
					Task { await game.endTurn() }
				}
				.disabled(game.match?.isLocalPlayersTurn != true)
				.padding()
				
				Spacer()

				if isReloading {
					ProgressView()
				} else {
					Button(action: { reloadMatch() }) {
						Image(systemName: "arrow.clockwise")
							.padding()
					}
				}
			}
		}
	}
}

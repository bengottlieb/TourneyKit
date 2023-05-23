//
//  TTTGameView.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/22/23.
//

import SwiftUI

struct TTTGameView: View {
	@ObservedObject var game: TTTGame
	
	var body: some View {
		VStack {
			Text("TTT Game")
			
			Spacer()
			
			Button("End Turn") {
				Task {
					do {
						try await game.match?.endTurn()
						game.objectWillChange.send()
					} catch {
						print("Failed to end turn: \(error)")
					}
				}
			}
			.disabled(game.match?.isLocalPlayersTurn != true)
			
		}
	}
}

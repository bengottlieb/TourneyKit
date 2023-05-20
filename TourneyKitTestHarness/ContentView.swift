//
//  ContentView.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import TourneyKit
import GameKit


struct ContentView: View {
	@State var game = RPSGame()
	@ObservedObject var mgr = MatchManager.instance

	var body: some View {
		VStack {
			if game.isStarted {
				RPSGameView(game: game)
			} else {
				Button("Start") {
					Task {
						try await mgr.startAutomatching(request: game.request, delegate: game)
					}
				}
				.disabled(mgr.isAutomatching)
			}
		}
		.onAppear {
			mgr.authenticate()
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

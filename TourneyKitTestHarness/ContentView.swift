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
				HStack {
					Button(mgr.isAutomatching ? "Searching…" : "Start") { startGame() }
						.disabled(mgr.isAutomatching)
					Button(action: cancelStart) {
						Image(systemName: "x.circle.fill")
							.opacity(0.5)
					}
					.buttonStyle(.plain)
					.opacity(mgr.isAutomatching ? 1 : 0)
				}
			}
		}
		.onAppear {
			mgr.authenticate()
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) { mgr.showingGameCenterAvatar = false }
		}
	}
	
	func startGame() {
		Task {
			try await mgr.startAutomatching(request: game.request, delegate: game)
		}
	}
	
	func cancelStart() {
		mgr.cancelAutomatching()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

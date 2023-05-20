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
	@State var matchView: MatchmakerView?
	@State var match: GKMatch?

	var body: some View {
		VStack {
			if game.isStarted {
				RPSGameView(game: game)
			} else {
				Button("Search for Players") {
					matchView = MatchmakerView(request: game.request, match: $match)
				}
				HStack {
					Button(mgr.isAutomatching ? "Searching…" : "Automatch") { startGame() }
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
		.sheet(item: $matchView) { view in
			view.edgesIgnoringSafeArea(.all)
		}
		.onChange(of: match) { newValue in
			if let newValue {
				mgr.load(match: newValue, delegate: game)
			}
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

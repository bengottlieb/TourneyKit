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
	@State var turnBasedGame: TTTGame?
	@ObservedObject var mgr = MatchManager.instance
	@State var matchView: RealTimeMatchmakerView?
	@State var match: GKMatch?
	@State var showingTurnBasedUI = false
	@State var turnBasedMatch: GKTurnBasedMatch?
	
	var body: some View {
		VStack(spacing: 5) {
			if let turnBased = turnBasedGame {
				TTTGameView(game: turnBased)
			} else if game.isStarted {
				RPSGameView(game: game)
			} else {
				Text("\(GKLocalPlayer.local.displayName) - \(GKLocalPlayer.local.tourneyKitID ?? "--")")
				Spacer()
				
				Text("Real Time Matches")
				Button("Search for Players") {
					matchView = RealTimeMatchmakerView(request: game.request, match: $match)
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
				
				Text("Turn Based Matches")
				Button(action: { showingTurnBasedUI.toggle() }) {
					Text("Start Turn Based")
				}
			}
			Spacer()
		}
		.onAppear {
			mgr.authenticate()
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) { mgr.showingGameCenterAvatar = false }
		}
		.sheet(item: $matchView) { view in
			view.edgesIgnoringSafeArea(.all)
		}
		.sheet(isPresented: $showingTurnBasedUI) {
			TurnBasedMatchmakerView(request: game.request, match: $turnBasedMatch)
				.edgesIgnoringSafeArea(.all)
		}
		.onChange(of: turnBasedMatch) { match in
			guard let match else { return }
			let game = TTTGame()
			MatchManager.instance.load(match: match, delegate: game)
			turnBasedGame = game
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

//
//  ContentView.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import TourneyKit
import GameKit
import Combine


struct ContentView: View {
	@State var game = RealTimeGameExample()
	@State var turnBasedGame: TurnBasedGameExample?
	@EnvironmentObject var mgr: MatchManager
	@State var matchView: RealTimeMatchmakerView?
	@State var match: GKMatch?
	@State var showingTurnBasedUI = false
	@AppStorage("auto_restore_last_match") var autoRestoreLastMatch = false
	@State var authenticationPublisher: AnyCancellable?
	
	var body: some View {
		VStack(spacing: 5) {
			if let turnBased = mgr.turnBasedActiveMatch?.parentGame as? TurnBasedGameExample {
				TurnBasedGameView(game: turnBased)
			} else if game.isStarted {
				RealTimeGameView(game: game)
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
				Button(action: { mgr.pendingMatchRequest = TurnBasedGameExample.defaultRequest }) {
					Text("Start Turn Based")
				}
				if mgr.canRestoreMatch {
					Button(action: { restore() }) {
						Text("Restore Last Game")
					}
				}
				Toggle("Auto Restore Last Match", isOn: $autoRestoreLastMatch)
			}
			Spacer()
		}
		.padding()
		.onAppear {
			authenticationPublisher = GameCenterInterface.instance.authenticate()
				.sink { _ in
					DispatchQueue.main.async {
						GameCenterInterface.instance.showingGameCenterAvatar = false
						if autoRestoreLastMatch, turnBasedGame == nil {
							appLogger.info("Restoring: \(autoRestoreLastMatch)")
							restore()
						}
					}
				}
		}
		.sheet(item: $matchView) { view in
			view.edgesIgnoringSafeArea(.all)
		}
		.sheet(item: $mgr.pendingMatchRequest) { request in
			TurnBasedMatchmakerView(request: request) { newMatch in
				turnBasedGame = TurnBasedGameExample()
				mgr.load(match: newMatch, game: turnBasedGame!)
			}
			.edgesIgnoringSafeArea(.all)
		}
		.onChange(of: match) { newValue in
			if let newValue {
				mgr.load(match: newValue, game: game)
			}
		}
	}
	
	func startGame() {
		Task {
			try await mgr.startAutomatching(request: game.request, game: game)
		}
	}
	
	func cancelStart() {
		mgr.cancelAutomatching()
	}
	
	func restore() {
		let game = TurnBasedGameExample()
		Task {
			do {
				try await mgr.restore(game: game)
				self.turnBasedGame = game
			} catch {
				appLogger.info("Failed to restore game: \(error)")
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

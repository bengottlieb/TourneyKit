//
//  RealTimeGameView.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import TourneyKit

struct RealTimeGameView: View {
	@ObservedObject var game: RealTimeGameExample
	@State var showLog = false
	var body: some View {
		ZStack {
			VStack {
				Text(game.match?.phase.title ?? "--")
				ForEach(game.players.indices, id: \.self) { idx in
					let player = game.players[idx]
					HStack {
						PlayerLabel(player: player)
					}
				}
				
				let allMoves = game.state.moves
				let sortedPlayers = game.players.sorted { $0.displayName < $1.displayName }
				ForEach(allMoves.indices, id: \.self) { idx in
					let move = game.state.moves[idx]
					HStack {
						ForEach(sortedPlayers.indices, id: \.self) { idx in
							let player = sortedPlayers[idx]
							Text(player.displayName)
							if let tourneyKitID = player.tourneyKitID, let move = move.moves[tourneyKitID] {
								Text(move)
							}
						}
						
					}
					Rectangle()
						.fill(Color.gray)
						.frame(height: 1)
				}
				
				HStack {
					Button("🪨") { move("🪨") }
					Button("📄") { move("📄") }
					Button("✂️") { move("✂️") }
				}
				.font(.system(size: 30))
				.disabled(!game.canMove)
				.opacity(game.canMove ? 1 : 0.25)
				
				Spacer()
				HStack {
					Button(game.match?.phase == .ended ? "Done" : "End Game") {
						if game.match?.phase == .ended {
							game.terminateGame()
						} else {
							game.endGame()
						}
					}
					Spacer()
					Button("🐞") { showLog.toggle() }
				}
				.padding(.horizontal)
			}
			
			if showLog {
				VStack {
					Rectangle().fill(Color.clear)
					Rectangle().fill(Color.clear)
						.background {
							LoggerView()
								.opacity(0.7)
						}
						.padding(.horizontal)
						.padding(.bottom, 30)
				}
			}
		}
	}
	
	func name(for playerID: String) -> String? {
		game.players.first { $0.tourneyKitID == playerID }?.displayName
	}
	
	func move(_ move: String) {
		game.makeMove(move)
	}
}
//
//struct RealTimeGameView_Previews: PreviewProvider {
//    static var previews: some View {
//        RPSGameState()
//    }
//}

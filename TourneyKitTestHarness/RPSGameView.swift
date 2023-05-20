//
//  RPSGameView.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI

struct RPSGameView: View {
	@ObservedObject var game: RPSGame
	
	var body: some View {
		VStack {
			Text(game.match?.phase.title ?? "--")
			ForEach(game.players, id: \.gamePlayerID) { player in
				HStack {
					Text(player.displayName)
				}
			}

			let allMoves = game.state.moves
			let sortedPlayers = game.players.sorted { $0.displayName < $1.displayName }
			ForEach(allMoves.indices, id: \.self) { idx in
				let move = game.state.moves[idx]
				HStack {
					ForEach(sortedPlayers, id: \.gamePlayerID) { player in
						Text(player.displayName)
						if let move = move.moves[player.gamePlayerID] {
							Text(move)
						}
					}
				}
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
			Button(game.match?.phase == .ended ? "Done" : "End Game") {
				if game.match?.phase == .ended {
					game.terminateGame()
				} else {
					game.endGame()
				}
			}
		}
	}
	
	func name(for playerID: String) -> String? {
		game.players.first { $0.gamePlayerID == playerID }?.displayName
	}
	
	func move(_ move: String) {
		game.makeMove(move)
	}
}
//
//struct RPSGameView_Previews: PreviewProvider {
//    static var previews: some View {
//        RPSGameState()
//    }
//}

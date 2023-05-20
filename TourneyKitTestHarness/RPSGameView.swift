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
			ForEach(game.players, id: \.teamPlayerID) { player in
				HStack {
					Text(player.displayName)
				}
			}

			ForEach(game.state.moves.indices, id: \.self) { idx in
				let move = game.state.moves[idx]
				HStack {
					Text(move.moves.values.joined(separator: ", "))
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
					game.match?.terminate()
				} else {
					game.endGame()
				}
			}
		}
		
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

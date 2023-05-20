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
		let _ = Self._printChanges()
		
		VStack {
			ForEach(game.players, id: \.teamPlayerID) { player in
				HStack {
					Text(player.displayName)
				}
			}
			Spacer()
			Button("End Game") {
				game.endGame()
			}
		}
	}
}
//
//struct RPSGameView_Previews: PreviewProvider {
//    static var previews: some View {
//        RPSGameState()
//    }
//}

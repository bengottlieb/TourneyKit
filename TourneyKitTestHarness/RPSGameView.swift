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
			ForEach(game.players, id: \.teamPlayerID) { player in
				HStack {
					Text(player.displayName)
				}
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

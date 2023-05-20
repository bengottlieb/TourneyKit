//
//  BasicControlPanel.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import GameKit
import TourneyKit

struct BasicControlPanel: View {
	@ObservedObject var mgr = MatchManager.instance
	var body: some View {
		VStack(spacing: 10) {
			Button("Authenticated: \(mgr.isAuthenticated ? "Yes" : "No")") {
				mgr.authenticate()
			}
			.disabled(mgr.isAuthenticated)
			
			Text("Matching: \(mgr.isAutomatching ? "On" : "Off")")
			Text("Has Match: \(mgr.isInMatch ? "Yes" : "No")")

			Button(action: startMatching) { Text("Start matching") }
				.disabled(mgr.isAutomatching)

			Button(action: stopMatching) { Text("Stop matching") }
				.disabled(!mgr.isAutomatching)
			
			Button("Start") {
				try! mgr.activeMatch?.send(message: MessageMatchStart())
			}
			.disabled(!mgr.isInMatch)
		}
		.padding()
		.onAppear {
			mgr.authenticate()
			mgr.showingGameCenterAvatar = false
		}
	}
	
	func startMatching() {
		Task {
			let request = GKMatchRequest()
			request.playerRange = 2...2
			try await mgr.startAutomatching(request: request)
		}
	}
	
	func stopMatching() {
		mgr.cancelAutomatching()
	}
}

struct BasicControlPanel_Previews: PreviewProvider {
    static var previews: some View {
        BasicControlPanel()
    }
}

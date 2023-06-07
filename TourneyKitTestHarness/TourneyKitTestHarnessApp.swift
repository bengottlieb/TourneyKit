//
//  TourneyKitTestHarnessApp.swift
//  TourneyKitTestHarness
//
//  Created by Ben Gottlieb on 5/19/23.
//

import SwiftUI
import TourneyKit
import OSLog

let appLogger = Logger(subsystem: "app", category: "info")

@main
struct TourneyKitTestHarnessApp: App {
	init() {
		
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(MatchManager.instance)
		}
	}
}

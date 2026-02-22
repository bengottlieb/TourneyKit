//
//  TurnBasedMatchmakerView.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

#if canImport(UIKit)
import SwiftUI
import GameKit

public struct TurnBasedMatchmakerView: UIViewControllerRepresentable, Identifiable {
	@State var controller: GKTurnBasedMatchmakerViewController
	public let id = UUID()
	@Environment(\.dismiss) var dismiss
	var completion: @MainActor (GKTurnBasedMatch) -> Void

	public init(request: GKMatchRequest, match: Binding<GKTurnBasedMatch?>) {
		_controller = State(initialValue: GKTurnBasedMatchmakerViewController(matchRequest: request))
		completion = { newMatch in
			match.wrappedValue = newMatch
		}
	}

	public init<Game: TurnBasedMatch>(request: GKMatchRequest, game: Game) {
		_controller = State(initialValue: GKTurnBasedMatchmakerViewController(matchRequest: request))
		completion = { newMatch in
			MatchManager.instance.load(match: newMatch, game: game)
		}
	}

	public init(request: GKMatchRequest, completion: @escaping @MainActor (GKTurnBasedMatch) -> Void) {
		_controller = State(initialValue: GKTurnBasedMatchmakerViewController(matchRequest: request))
		self.completion = completion
	}
	
	public func makeUIViewController(context: Context) -> some UIViewController {
		controller
	}
	
	public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator(view: self)
	}
	
	@MainActor public class Coordinator: NSObject, @preconcurrency GKTurnBasedMatchmakerViewControllerDelegate {
		let view: TurnBasedMatchmakerView

		init(view: TurnBasedMatchmakerView) {
			self.view = view
			super.init()
			view.controller.turnBasedMatchmakerDelegate = self
		}

		public func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
			view.dismiss()
		}

		public func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFind match: GKTurnBasedMatch) {
			view.completion(match)
			view.dismiss()
		}

		public func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
			tourneyLogger.error("Error when turn-based matchmaking: \(error)")
			view.dismiss()
		}

	}
}
#endif

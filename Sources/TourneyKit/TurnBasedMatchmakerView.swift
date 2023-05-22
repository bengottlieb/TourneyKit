//
//  TurnBasedMatchmakerView.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI
import GameKit

public struct TurnBasedMatchmakerView: UIViewControllerRepresentable, Identifiable {
	@State var controller: GKTurnBasedMatchmakerViewController
	@Binding var match: GKTurnBasedMatch?
	public var id: NSObject { controller }
	@Environment(\.dismiss) var dismiss
	
	public init(request: GKMatchRequest, match: Binding<GKTurnBasedMatch?>) {
		_controller = State(initialValue: GKTurnBasedMatchmakerViewController(matchRequest: request))
		_match = match
	}
	
	public func makeUIViewController(context: Context) -> some UIViewController {
		controller
	}
	
	public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator(view: self)
	}
	
	public class Coordinator: NSObject, GKTurnBasedMatchmakerViewControllerDelegate {
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
			view.match = match
			view.dismiss()
		}

		public func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
			print("Error when matchmaking: \(error)")
			view.dismiss()
		}
		
	}
}

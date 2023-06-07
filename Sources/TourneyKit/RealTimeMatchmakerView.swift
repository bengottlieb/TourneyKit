//
//  SwiftUIView.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import SwiftUI
import GameKit

public struct RealTimeMatchmakerView: UIViewControllerRepresentable, Identifiable {
	@State var controller: GKMatchmakerViewController
	@Binding var match: GKMatch?
	public var id: NSObject { controller }
	@Environment(\.dismiss) var dismiss
	
	public init?(request: GKMatchRequest, match: Binding<GKMatch?>) {
		guard let cnt = GKMatchmakerViewController(matchRequest: request) else { return nil }
		
		_controller = State(initialValue: cnt)
		_match = match
	}
	
	public init?(invite: GKInvite, match: Binding<GKMatch?>) {
		guard let cnt = GKMatchmakerViewController(invite: invite) else { return nil }
		
		_controller = State(initialValue: cnt)
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
	
	public class Coordinator: NSObject, GKMatchmakerViewControllerDelegate {
		let view: RealTimeMatchmakerView
		
		init(view: RealTimeMatchmakerView) {
			self.view = view
			super.init()
			view.controller.matchmakerDelegate = self
		}

		public func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
			view.dismiss()
		}
		
		public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
			view.match = match
			view.dismiss()
		}

		public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
			tourneyLogger.error("Error when matchmaking: \(error)")
			view.dismiss()
		}
		
	}
}

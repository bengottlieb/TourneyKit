//
//  SwiftUIView.swift
//  
//
//  Created by Ben Gottlieb on 5/20/23.
//

import SwiftUI
import GameKit

public struct MatchmakerView: UIViewControllerRepresentable {
	@State var controller: GKMatchmakerViewController
	
	init?(request: GKMatchRequest) {
		guard let cnt = GKMatchmakerViewController(matchRequest: request) else { return nil }
		
		_controller = State(initialValue: cnt)
	}
	
	init?(invite: GKInvite) {
		guard let cnt = GKMatchmakerViewController(invite: invite) else { return nil }
		
		_controller = State(initialValue: cnt)
	}
	

	public func makeUIViewController(context: Context) -> some UIViewController {
		controller
	}
	
	public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		
	}
}

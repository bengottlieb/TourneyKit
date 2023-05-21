//
//  GKPlayerConnectionState.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import Foundation
import GameKit


extension GKPlayerConnectionState: CustomStringConvertible {
	public var description: String {
		switch self {
		case .connected: return "connected"
		case .disconnected: return "disconnected"
		
		case .unknown: return "unknown"
		@unknown default: return "@unknown"
		}
	}
}

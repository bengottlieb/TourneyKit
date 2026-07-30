//
//  File.swift
//  TourneyKit
//
//  Created by Ben Gottlieb on 7/30/26.
//

import Foundation
import GameKit

public extension Error {
	var isFailedToConnectToGameCenter: Bool {
		let error = self as NSError
		
		if error.domain == GKErrorDomain, error.code == 15 {
			return true
		}
		return false
	}
}

//
//  SomeGameKitMatch.swift
//  
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit

@MainActor public protocol SomeGameKitMatch: AnyObject {
	var turnBasedMatch: GKTurnBasedMatch? { get }
	var realTimeMatch: GKMatch? { get }
	
	var parentContainer: AnyObject? { get }
}

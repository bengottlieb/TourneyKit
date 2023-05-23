//
//  SomeMatch.swift
//  
//
//  Created by Ben Gottlieb on 5/22/23.
//

import Foundation
import GameKit

public protocol SomeMatch: AnyObject {
	var turnBasedMatch: GKTurnBasedMatch? { get }
	var realTimeMatch: GKMatch? { get }
	
	var parentGame: AnyObject? { get }
}

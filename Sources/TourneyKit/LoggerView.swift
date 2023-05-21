//
//  LoggerView.swift
//  
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI

public struct LoggerView: View {
	@ObservedObject var logger = Logger.instance
	
	public init() { }
	
	public var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading) {
				ForEach(logger.messages.indices, id: \.self) { idx in
					let text = logger.messages[idx].description
					Text(text)
						.id(text)
				}
				.id(logger.lastMessageAt)
			}
			.font(.system(size: 12).monospaced())
			
		}
	}
}

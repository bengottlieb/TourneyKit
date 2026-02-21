//
//  LoggerView.swift
//
//
//  Created by Ben Gottlieb on 5/21/23.
//

import SwiftUI

public struct LoggerView: View {
	public init() { }

	public var body: some View {
		let logger = TKLogger.instance
		ScrollView {
			LazyVStack(alignment: .leading) {
				ForEach(logger.messages.indices, id: \.self) { idx in
					let text = logger.messages[idx].description
					Text(text)
						.foregroundStyle(.white)
				}
				.id(logger.lastMessageAt)
			}
			.font(.system(size: 12).monospaced())
			.padding(4)
			.background(Color.black)
		}
	}
}

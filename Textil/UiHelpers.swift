//
//  UiHelpers.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//

import SwiftUI

extension View {
    func infoBox() -> some View {
        self
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

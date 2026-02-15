//
//  Placeholder+View.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            content().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

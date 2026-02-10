//
//  FormSection.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  FormSection.swift
//  Textil
//

import SwiftUI

struct FormSection<Content: View>: View {

    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                content
                    .padding()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

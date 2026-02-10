//
//  NumericTextField.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  NumericTextField.swift
//  Textil
//

import SwiftUI

struct NumericTextField: View {

    let placeholder: String
    @Binding var value: Double
    let suffix: String?

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    init(
        placeholder: String,
        value: Binding<Double>,
        suffix: String? = nil
    ) {
        self.placeholder = placeholder
        self._value = value
        self.suffix = suffix
    }

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .multilineTextAlignment(.trailing)
                .onAppear {
                    if value > 0 {
                        text = CurrencyFormatter.rawString(from: value)
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        aplicarFormato()
                    }
                }

            if let suffix {
                Text(suffix)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func aplicarFormato() {
        let limpio = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let numero = Double(limpio) ?? 0
        value = numero

        text = numero > 0
            ? CurrencyFormatter.formattedString(from: numero)
            : ""
    }
}

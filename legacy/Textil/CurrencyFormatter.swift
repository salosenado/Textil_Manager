//
//  CurrencyFormatter.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CurrencyFormatter.swift
//  Textil
//

import Foundation

enum CurrencyFormatter {

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.decimalSeparator = "."
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static func formattedString(from value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? ""
    }

    // SIN formato (para editar libre)
    static func rawString(from value: Double) -> String {
        value == 0 ? "" : String(value)
    }
}

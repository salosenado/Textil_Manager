//
//  Extensions.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//

import Foundation

extension Double {

    var formatoMoneda: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "0.00"
    }
}

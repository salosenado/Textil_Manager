//
//  ReingresoHelpers.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  ReingresoHelpers.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

import Foundation

// =========================
// FORMATO MONEDA
// =========================
func formatoMoneda(_ valor: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "MXN"
    return formatter.string(from: NSNumber(value: valor)) ?? "$0.00"
}

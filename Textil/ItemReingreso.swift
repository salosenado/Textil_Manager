//
//  ItemReingreso.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
import Foundation

struct ItemReingreso: Identifiable {
    let id = UUID()
    let esServicio: Bool
    let nombre: String
    let talla: String?
    let unidad: String?
    let cantidad: Int
    let costoUnitario: Double

    var total: Double {
        Double(cantidad) * costoUnitario
    }
}

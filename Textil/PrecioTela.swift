//
//  PrecioTela.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  PrecioTela.swift
//  Textil
//

import Foundation
import SwiftData

@Model
class PrecioTela {

    var tipo: String        // Blanco, Claro, Medio, etc.
    var precio: Double
    var fecha: Date

    init(
        tipo: String,
        precio: Double,
        fecha: Date = .now
    ) {
        self.tipo = tipo
        self.precio = precio
        self.fecha = fecha
    }
}

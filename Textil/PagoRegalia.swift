//
//  PagoRegalia.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftData
import Foundation

@Model
class PagoRegalia {

    var fecha: Date
    var monto: Double

    @Relationship
    var marca: Marca?

    init(
        fecha: Date = Date(),
        monto: Double,
        marca: Marca?
    ) {
        self.fecha = fecha
        self.monto = monto
        self.marca = marca
    }
}

//
//  CobroVenta.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftData
import Foundation

@Model
class CobroVenta {

    var fechaCobro: Date
    var monto: Double
    var referencia: String
    var observaciones: String

    @Relationship
    var venta: VentaCliente?

    var fechaEliminacion: Date?

    init(
        fechaCobro: Date = Date(),
        monto: Double,
        referencia: String = "",
        observaciones: String = "",
        venta: VentaCliente?
    ) {
        self.fechaCobro = fechaCobro
        self.monto = monto
        self.referencia = referencia
        self.observaciones = observaciones
        self.venta = venta
        self.fechaEliminacion = nil
    }
}

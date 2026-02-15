//
//  ReciboCompraPago.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//


import SwiftData
import Foundation

@Model
class ReciboCompraPago {

    var fechaPago: Date
    var monto: Double
    var observaciones: String

    @Relationship
    var recibo: ReciboCompra?

    // AUDITORÍA
    var usuarioEliminacion: String?
    var fechaEliminacion: Date?

    init(
        monto: Double,
        observaciones: String = "",
        recibo: ReciboCompra?
    ) {
        self.monto = monto
        self.observaciones = observaciones
        self.recibo = recibo
        self.fechaPago = Date()
    }
}

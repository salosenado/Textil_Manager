//
//  PagoRecibo.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
//
//  PagoRecibo.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftData
import Foundation

@Model
class PagoRecibo {

    // MARK: - DATOS

    var fechaPago: Date
    var monto: Double
    var observaciones: String

    // MARK: - RELACIÓN

    @Relationship
    var recibo: ReciboProduccion?

    // MARK: - AUDITORÍA (ESTO FALTABA)

    var usuarioEliminacion: String?
    var fechaEliminacion: Date?

    // MARK: - INIT (COINCIDE CON TU USO)

    init(
        monto: Double,
        observaciones: String = "",
        recibo: ReciboProduccion?
    ) {
        self.monto = monto
        self.observaciones = observaciones
        self.recibo = recibo
        self.fechaPago = Date()
    }
}

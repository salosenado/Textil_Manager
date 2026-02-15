//
//  MoviemientoFinancieroVenta.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//

import SwiftData
import Foundation

enum TipoMovimientoVenta: String, Codable {
    case pago
    case factoraje
    case fillRate
    case descuento
}

@Model
class MovimientoFinancieroVenta {

    var fecha: Date
    var monto: Double
    var tipoRaw: String
    var observaciones: String

    @Relationship
    var venta: VentaCliente?

    var fechaEliminacion: Date?

    init(
        fecha: Date = Date(),
        monto: Double,
        tipo: TipoMovimientoVenta,
        observaciones: String = "",
        venta: VentaCliente?
    ) {
        self.fecha = fecha
        self.monto = monto
        self.tipoRaw = tipo.rawValue
        self.observaciones = observaciones
        self.venta = venta
        self.fechaEliminacion = nil
    }

    var tipo: TipoMovimientoVenta {
        TipoMovimientoVenta(rawValue: tipoRaw) ?? .pago
    }
}

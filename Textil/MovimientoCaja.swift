//
//  MovimientoCaja.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftData
import Foundation

@Model
class MovimientoCaja {

    enum Tipo: String, Codable {
        case ingreso
        case egreso
    }

    var tipoRaw: String
    var fecha: Date
    var monto: Double

    // Solo para ingreso
    var cliente: String?

    // Solo para egreso
    var razon: String?

    init(
        tipo: Tipo,
        fecha: Date,
        monto: Double,
        cliente: String? = nil,
        razon: String? = nil
    ) {
        self.tipoRaw = tipo.rawValue
        self.fecha = fecha
        self.monto = monto
        self.cliente = cliente
        self.razon = razon
    }

    var tipo: Tipo {
        Tipo(rawValue: tipoRaw) ?? .ingreso
    }

    var esIngreso: Bool {
        tipo == .ingreso
    }

    var montoFirmado: Double {
        esIngreso ? monto : -monto
    }
}

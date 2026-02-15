//
//  MovimientoBanco.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//

import SwiftData
import Foundation

@Model
class MovimientoBanco {

    enum Tipo: String, Codable {
        case ingreso
        case egreso
    }

    var tipo: Tipo
    var fecha: Date
    var monto: Double

    var empresa: Empresa?

    var cliente: Cliente?
    var proveedor: Proveedor?

    var descripcion: String?

    init(
        tipo: Tipo,
        fecha: Date,
        monto: Double,
        empresa: Empresa?,
        cliente: Cliente?,
        proveedor: Proveedor?,
        descripcion: String?
    ) {
        self.tipo = tipo
        self.fecha = fecha
        self.monto = monto
        self.empresa = empresa
        self.cliente = cliente
        self.proveedor = proveedor
        self.descripcion = descripcion
    }

    var esIngreso: Bool {
        tipo == .ingreso
    }

    var montoFirmado: Double {
        esIngreso ? monto : -monto
    }
}

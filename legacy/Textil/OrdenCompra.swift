//
//  OrdenCompra.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftData
import Foundation

@Model
class OrdenCompra {

    @Attribute(.unique) var numeroOC: Int

    var proveedor: String
    var plazoDias: Int?

    var fechaOrden: Date
    var fechaEntrega: Date

    var aplicaIVA: Bool
    var tipoCompra: String        // 👈 NUEVO (cliente | insumo)
    var observaciones: String

    var cancelada: Bool = false
    var historial: [OrdenMovimiento] = []
    
    @Relationship(deleteRule: .cascade)
    var detalles: [OrdenCompraDetalle]

    init(
        numeroOC: Int,
        proveedor: String,
        plazoDias: Int?,
        fechaOrden: Date,
        fechaEntrega: Date,
        aplicaIVA: Bool,
        tipoCompra: String,        // 👈 NUEVO
        observaciones: String = "",
        detalles: [OrdenCompraDetalle] = []
    ) {
        self.numeroOC = numeroOC
        self.proveedor = proveedor
        self.plazoDias = plazoDias
        self.fechaOrden = fechaOrden
        self.fechaEntrega = fechaEntrega
        self.aplicaIVA = aplicaIVA
        self.tipoCompra = tipoCompra
        self.observaciones = observaciones
        self.detalles = detalles
    }
}
extension OrdenCompra {

    var folio: String {
        let numero = String(format: "%03d", numeroOC)

        switch tipoCompra {
        case "cliente":
            return "OC-\(numero)"
        case "insumo":
            return "OCI-\(numero)"
        case "servicio":
            return "SS-\(numero)"
        default:
            return "OC-\(numero)"
        }
    }
}


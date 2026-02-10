//
//  ReciboDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftData
import Foundation

@Model
class ReciboDetalle {

    // MARK: - DATOS PRINCIPALES

    var modelo: String
    var pzPrimera: Int
    var pzSaldo: Int

    // MARK: - RELACIONES (IMPORTANTE PARA SWIFTDATA)

    @Relationship
    var recibo: ReciboProduccion?

    @Relationship
    var detalleOrden: OrdenClienteDetalle?

    // MARK: - OBSERVACIONES

    var observaciones: String?
    var notaFactura: String?        // 👈 TIENE QUE ESTAR AQUÍ

    // MARK: - AUDITORÍA

    var usuarioEliminacion: String?
    var fechaEliminacion: Date?

    // MARK: - INIT (NO SE INVENTA, ES EL TUYO)

    init(
        modelo: String,
        pzPrimera: Int,
        pzSaldo: Int,
        recibo: ReciboProduccion?,
        detalleOrden: OrdenClienteDetalle?
    ) {
        self.modelo = modelo
        self.pzPrimera = pzPrimera
        self.pzSaldo = pzSaldo
        self.recibo = recibo
        self.detalleOrden = detalleOrden
    }
}

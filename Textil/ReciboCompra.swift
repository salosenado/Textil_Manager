//
//  ReciboCompra.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//


import SwiftData
import Foundation

@Model
class ReciboCompra {

    // RELACIÓN CLAVE
    @Relationship
    var orden: OrdenCompra

    // PAGOS
    @Relationship(deleteRule: .cascade)
    var pagos: [ReciboCompraPago] = []

    // DATOS
    var fechaRecibo: Date
    var observaciones: String = ""

    // ESTADO
    var cancelado: Bool = false
    var fechaCancelacion: Date?

    init(
        orden: OrdenCompra,
        fechaRecibo: Date = Date()
    ) {
        self.orden = orden
        self.fechaRecibo = fechaRecibo
    }
}

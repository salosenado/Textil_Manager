//
//  CompraCliente.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//


import SwiftData
import Foundation

@Model
class CompraCliente {

    @Attribute(.unique) var numeroCompra: Int

    var proveedorCliente: String
    var fechaCreacion: Date
    var fechaRecepcion: Date

    var aplicaIVA: Bool
    var observaciones: String

    @Relationship(deleteRule: .cascade)
    var detalles: [CompraClienteDetalle]

    init(
        numeroCompra: Int,
        proveedorCliente: String,
        fechaCreacion: Date,
        fechaRecepcion: Date,
        aplicaIVA: Bool,
        observaciones: String = "",
        detalles: [CompraClienteDetalle] = []
    ) {
        self.numeroCompra = numeroCompra
        self.proveedorCliente = proveedorCliente
        self.fechaCreacion = fechaCreacion
        self.fechaRecepcion = fechaRecepcion
        self.aplicaIVA = aplicaIVA
        self.observaciones = observaciones
        self.detalles = detalles
    }
}

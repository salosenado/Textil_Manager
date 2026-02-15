//
//  OrdenCliente.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
import SwiftData
import Foundation

@Model
class OrdenCliente {

    // DATOS
    var numeroVenta: Int
    var cliente: String
    var numeroPedidoCliente: String
    var fechaCreacion: Date
    var fechaEntrega: Date
    var aplicaIVA: Bool

    // RELACIONES
    var agente: Agente?

    @Relationship(deleteRule: .cascade)
    var detalles: [OrdenClienteDetalle] = []

    @Relationship(deleteRule: .cascade)
    var movimientos: [MovimientoPedido] = []

    // ESTADO
    var cancelada: Bool = false
    var usuarioCancelacion: String?
    var fechaCancelacion: Date?

    var ultimoUsuarioEdicion: String?
    var fechaUltimaEdicion: Date?

    init(
        numeroVenta: Int,
        cliente: String,
        numeroPedidoCliente: String,
        fechaCreacion: Date,
        fechaEntrega: Date,
        aplicaIVA: Bool,
        agente: Agente? = nil
    ) {
        self.numeroVenta = numeroVenta
        self.cliente = cliente
        self.numeroPedidoCliente = numeroPedidoCliente
        self.fechaCreacion = fechaCreacion
        self.fechaEntrega = fechaEntrega
        self.aplicaIVA = aplicaIVA
        self.agente = agente
    }
}

// TOTALES
extension OrdenCliente {
    var subtotal: Double {
        detalles.reduce(0) { $0 + $1.subtotal }
    }

    var iva: Double {
        aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }
}

//
//  VentaCliente.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
//
//  VentaCliente.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//

import SwiftData
import Foundation

@Model
class VentaCliente {

    // =====================================================
    // MARK: - DATOS GENERALES
    // =====================================================

    var folio: String
    var fechaVenta: Date
    var fechaEntrega: Date

    @Relationship
    var cliente: Cliente

    @Relationship
    var agente: Agente?

    var numeroFactura: String
    var aplicaIVA: Bool
    var observaciones: String

    // =====================================================
    // MARK: - RESPONSABLES
    // =====================================================

    var nombreAgenteVenta: String
    var nombreResponsableVenta: String

    // =====================================================
    // MARK: - FIRMAS DIGITALES
    // =====================================================

    @Attribute(.externalStorage)
    var firmaAgente: Data?

    @Attribute(.externalStorage)
    var firmaResponsable: Data?

    // =====================================================
    // MARK: - DOCUMENTO
    // =====================================================

    var documentoEmitido: Bool   // 🔒 Bloquea edición tras PDF

    // =====================================================
    // MARK: - EMPRESA
    // =====================================================

    var empresa: String

    // =====================================================
    // MARK: - ESTADO
    // =====================================================

    var cancelada: Bool
    var mercanciaEnviada: Bool
    var fechaEnvio: Date?

    // =====================================================
    // MARK: - RELACIONES
    // =====================================================

    @Relationship(deleteRule: .cascade)
    var detalles: [VentaClienteDetalle]

    @Relationship(deleteRule: .cascade)
    var movimientos: [VentaClienteMovimiento]

    // =====================================================
    // MARK: - INIT
    // =====================================================

    init(
        folio: String,
        fechaVenta: Date = Date(),
        fechaEntrega: Date,
        cliente: Cliente,
        agente: Agente?,
        numeroFactura: String,
        aplicaIVA: Bool,
        observaciones: String,
        empresa: String
    ) {
        self.folio = folio
        self.fechaVenta = fechaVenta
        self.fechaEntrega = fechaEntrega
        self.cliente = cliente
        self.agente = agente
        self.numeroFactura = numeroFactura
        self.aplicaIVA = aplicaIVA
        self.observaciones = observaciones
        self.empresa = empresa

        // Defaults seguros
        self.nombreAgenteVenta = ""
        self.nombreResponsableVenta = ""
        self.firmaAgente = nil
        self.firmaResponsable = nil
        self.documentoEmitido = false
        self.cancelada = false
        self.mercanciaEnviada = false
        self.fechaEnvio = nil
        self.detalles = []
        self.movimientos = []
    }
}

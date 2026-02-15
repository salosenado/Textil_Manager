//
//  SalidaInsumo.swift
//  Textil
//
//
//
//  SalidaInsumo.swift
//  Textil
//

import SwiftData
import Foundation

@Model
class SalidaInsumo {

    // =========================
    // GENERALES
    // =========================
    var fecha: Date
    var fechaEntrega: Date?

    var folio: String

    // Documento (NO es observación)
    var facturaNota: String = ""

    // Responsables
    var responsable: String = ""
    var recibeMaterial: String = ""

    // Texto libre
    var observaciones: String = ""

    // =========================
    // FIRMAS
    // =========================
    var firmaEntrega: Data?
    var firmaRecibe: Data?

    // =========================
    // RELACIONES
    // =========================
    @Relationship var empresa: Empresa?
    @Relationship var cliente: Cliente?
    @Relationship var agente: Agente?

    // =========================
    // ESTADOS
    // =========================
    var confirmada: Bool = false
    var cancelada: Bool = false
    var enviada: Bool = false

    var aplicaIVA: Bool = false

    // =========================
    // DETALLES Y MOVIMIENTOS
    // =========================
    @Relationship(deleteRule: .cascade)
    var detalles: [SalidaInsumoDetalle] = []

    @Relationship(deleteRule: .cascade)
    var movimientos: [SalidaInsumoMovimiento] = []

    // =========================
    // INIT
    // =========================
    init(
        fecha: Date,
        fechaEntrega: Date? = nil,
        folio: String,
        facturaNota: String = "",
        responsable: String = "",
        recibeMaterial: String = "",
        observaciones: String = "",
        empresa: Empresa? = nil,
        cliente: Cliente? = nil,
        agente: Agente? = nil
    ) {
        self.fecha = fecha
        self.fechaEntrega = fechaEntrega
        self.folio = folio
        self.facturaNota = facturaNota
        self.responsable = responsable
        self.recibeMaterial = recibeMaterial
        self.observaciones = observaciones
        self.empresa = empresa
        self.cliente = cliente
        self.agente = agente
    }
}

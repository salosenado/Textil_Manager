//
//  Reingreso.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//
//
//
//  Reingreso.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//

import Foundation
import SwiftData

@Model
class Reingreso {

    // MARK: - IDENTIDAD
    var folio: String
    var fecha: Date

    // MARK: - RELACIONES
    var empresa: Empresa?
    var cliente: Cliente?

    // MARK: - IVA
    var aplicaIVA: Bool

    // MARK: - RESPONSABLES
    var responsable: String
    var recibeMaterial: String

    // MARK: - REFERENCIA / NOTA
    var referencia: String

    // MARK: - ESTADO
    var confirmado: Bool
    var cancelado: Bool

    // MARK: - OBSERVACIONES
    var observaciones: String

    // MARK: - FIRMAS
    var firmaDevuelve: Data?
    var firmaRecibe: Data?

    // MARK: - DETALLES
    @Relationship(deleteRule: .cascade)
    var detalles: [ReingresoDetalle] = []

    // MARK: - MOVIMIENTOS
    @Relationship(deleteRule: .cascade)
    var movimientos: [ReingresoMovimiento] = []

    // MARK: - INIT VACÍO (SwiftData)
    init() {
        self.folio = ""
        self.fecha = Date()
        self.empresa = nil
        self.cliente = nil
        self.aplicaIVA = false
        self.responsable = ""
        self.recibeMaterial = ""
        self.referencia = ""
        self.confirmado = false
        self.cancelado = false
        self.observaciones = ""
        self.firmaDevuelve = nil
        self.firmaRecibe = nil
    }

    // MARK: - INIT USADO POR LA APP
    init(
        fecha: Date,
        folio: String,
        referencia: String,
        responsable: String,
        recibeMaterial: String,
        observaciones: String,
        empresa: Empresa?,
        cliente: Cliente?
    ) {
        self.fecha = fecha
        self.folio = folio
        self.referencia = referencia
        self.responsable = responsable
        self.recibeMaterial = recibeMaterial
        self.observaciones = observaciones
        self.empresa = empresa
        self.cliente = cliente

        self.aplicaIVA = false
        self.confirmado = false
        self.cancelado = false
        self.firmaDevuelve = nil
        self.firmaRecibe = nil
    }
}

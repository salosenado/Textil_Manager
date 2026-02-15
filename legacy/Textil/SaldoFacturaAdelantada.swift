//
//  SaldoFacturaAdelantada.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//

import SwiftData
import Foundation

@Model
class SaldoFacturaAdelantada {

    @Relationship(deleteRule: .cascade)
    var movimientos: [MovimientoFactura] = []
    
    var fecha: Date = Date()

    // 🔹 Datos de la factura
    var numeroFactura: String

    // 🔹 Empresa que emite la factura (tu empresa)
    var empresaNombre: String

    // 🔹 Empresa a la que se le debe
    var empresaAcreedor: String

    // 🔹 Información de contacto
    var dueno: String
    var contacto: String
    var email: String
    var telefono: String

    // 🔹 Datos financieros
    var subtotal: Double
    var iva: Double
    var total: Double

    // 🔹 Pagos
    var pagos: [PagoSaldoFactura] = []

    init(
        numeroFactura: String,
        empresaNombre: String,
        empresaAcreedor: String,
        dueno: String,
        contacto: String,
        email: String,
        telefono: String,
        subtotal: Double
    ) {
        self.numeroFactura = numeroFactura
        self.empresaNombre = empresaNombre
        self.empresaAcreedor = empresaAcreedor
        self.dueno = dueno
        self.contacto = contacto
        self.email = email
        self.telefono = telefono

        self.subtotal = subtotal
        self.iva = subtotal * 0.16
        self.total = subtotal * 1.16
    }

    // MARK: - CÁLCULOS DINÁMICOS

    var totalPagado: Double {
        pagos
            .filter { !$0.eliminado }
            .map { $0.monto }
            .reduce(0, +)
    }

    var saldoPendiente: Double {
        total - totalPagado
    }

    var estado: String {
        if saldoPendiente <= 0 {
            return "Finalizado"
        } else if saldoPendiente < total {
            return "Parcial"
        } else {
            return "Pendiente"
        }
    }
}

//
//  PagoSaldoFactura.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//


import SwiftData
import Foundation

@Model
class PagoSaldoFactura {

    var fecha: Date = Date()
    var monto: Double
    var usuario: String
    var eliminado: Bool = false

    init(monto: Double, usuario: String) {
        self.monto = monto
        self.usuario = usuario
    }
}

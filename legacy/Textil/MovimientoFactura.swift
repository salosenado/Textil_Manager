//
//  MovimientoFactura.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//


import Foundation
import SwiftData

@Model
class MovimientoFactura {

    var fecha: Date
    var tipo: String
    var descripcion: String
    var usuario: String
    var monto: Double?

    init(tipo: String,
         descripcion: String,
         usuario: String,
         monto: Double? = nil) {

        self.fecha = Date()
        self.tipo = tipo
        self.descripcion = descripcion
        self.usuario = usuario
        self.monto = monto
    }
}

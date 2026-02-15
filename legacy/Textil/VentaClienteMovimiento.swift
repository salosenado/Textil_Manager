//
//  VentaClienteMovimiento.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//


//
//  VentaClienteMovimiento.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//

import SwiftData
import Foundation

@Model
class VentaClienteMovimiento {

    var titulo: String
    var usuario: String
    var fecha: Date
    var icono: String
    var color: String

    @Relationship
    var venta: VentaCliente

    init(
        titulo: String,
        usuario: String,
        fecha: Date = Date(),
        icono: String,
        color: String,
        venta: VentaCliente
    ) {
        self.titulo = titulo
        self.usuario = usuario
        self.fecha = fecha
        self.icono = icono
        self.color = color
        self.venta = venta
    }
}

//
//  OrdenClienteEntity.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  OrdenClienteEntity.swift
//  Textil
//

import SwiftData
import Foundation

@Model
class OrdenClienteEntity {

    var cliente: String
    var pedido: String
    var modelo: String
    var cantidad: Int
    var fecha: Date
    var total: Double
    var sinIVA: Bool

    init(
        cliente: String,
        pedido: String,
        modelo: String,
        cantidad: Int,
        fecha: Date,
        total: Double,
        sinIVA: Bool
    ) {
        self.cliente = cliente
        self.pedido = pedido
        self.modelo = modelo
        self.cantidad = cantidad
        self.fecha = fecha
        self.total = total
        self.sinIVA = sinIVA
    }
}

//
//  CompraClienteDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//


import SwiftData
import Foundation

@Model
class CompraClienteDetalle {

    var articulo: String
    var linea: String
    var modelo: String
    var color: String
    var talla: String
    var unidad: String

    var cantidad: Int
    var costoUnitario: Double

    var compra: CompraCliente?

    var subtotal: Double {
        Double(cantidad) * costoUnitario
    }

    init(
        articulo: String,
        linea: String,
        modelo: String,
        color: String,
        talla: String,
        unidad: String,
        cantidad: Int,
        costoUnitario: Double
    ) {
        self.articulo = articulo
        self.linea = linea
        self.modelo = modelo
        self.color = color
        self.talla = talla
        self.unidad = unidad
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
    }
}

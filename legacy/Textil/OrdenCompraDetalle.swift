//
//  OrdenCompraDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//


import SwiftData
import Foundation

@Model
class OrdenCompraDetalle {

    var articulo: String
    var modelo: String
    var cantidad: Int
    var costoUnitario: Double

    var modeloCatalogo: Modelo?
    
    var orden: OrdenCompra?

    var subtotal: Double {
        Double(cantidad) * costoUnitario
    }

    init(
        articulo: String,
        modelo: String,
        cantidad: Int,
        costoUnitario: Double
    ) {
        self.articulo = articulo
        self.modelo = modelo
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
    }
}

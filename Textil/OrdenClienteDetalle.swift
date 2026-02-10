//
//  OrdenClienteDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
import Foundation
import SwiftData

@Model
class OrdenClienteDetalle {

    var articulo: String
    var linea: String
    var modelo: String
    var color: String
    var talla: String
    var unidad: String
    var cantidad: Int
    var precioUnitario: Double

    // 🔑 RELACIÓN SIMPLE (SIN inverse)
    @Relationship
    var orden: OrdenCliente?

    @Relationship
    var produccion: Produccion?

    @Relationship
    var modeloCatalogo: Modelo?

    init(
        articulo: String,
        linea: String,
        modelo: String,
        color: String,
        talla: String,
        unidad: String,
        cantidad: Int,
        precioUnitario: Double,
        modeloCatalogo: Modelo? = nil
    ) {
        self.articulo = articulo
        self.linea = linea
        self.modelo = modelo
        self.color = color
        self.talla = talla
        self.unidad = unidad
        self.cantidad = cantidad
        self.precioUnitario = precioUnitario
        self.modeloCatalogo = modeloCatalogo
    }

    var subtotal: Double {
        Double(cantidad) * precioUnitario
    }
}


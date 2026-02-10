//
//  Articulo.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  Articulo.swift
//  Textil
//

import SwiftData

@Model
class Articulo {

    var nombre: String
    var sku: String
    var descripcion: String

    // IMPORTES SOLO VISUALES
    var precioVenta: String
    var costo: String

    var activo: Bool

    init() {
        self.nombre = ""
        self.sku = ""
        self.descripcion = ""
        self.precioVenta = ""
        self.costo = ""
        self.activo = true
    }
}

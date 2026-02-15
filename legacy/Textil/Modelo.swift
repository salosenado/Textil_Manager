//
//  Modelo.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  Modelo.swift
//  Textil
//

import SwiftData

@Model
class Modelo {

    var nombre: String
    var codigo: String
    var descripcion: String

    // 🔢 INVENTARIO
    var existencia: Int
    
    // 🏷 MARCA (NUEVO)
        @Relationship
        var marca: Marca?

    init(
        nombre: String = "",
        codigo: String = "",
        descripcion: String = "",
        existencia: Int = 0
    ) {
        self.nombre = nombre
        self.codigo = codigo
        self.descripcion = descripcion
        self.existencia = existencia
    }
}

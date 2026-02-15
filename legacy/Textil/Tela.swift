//
//  Tela.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Tela.swift
//  Textil
//

import SwiftData

@Model
class Tela {

    var nombre: String
    var composicion: String
    var proveedor: String
    var descripcion: String
    var activa: Bool

    @Relationship(deleteRule: .cascade)
    var precios: [PrecioTela]

    init(
        nombre: String = "",
        composicion: String = "",
        proveedor: String = "",
        descripcion: String = "",
        activa: Bool = true,
        precios: [PrecioTela] = []
    ) {
        self.nombre = nombre
        self.composicion = composicion
        self.proveedor = proveedor
        self.descripcion = descripcion
        self.activa = activa
        self.precios = precios
    }
}

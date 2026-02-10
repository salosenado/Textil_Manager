//
//  Talla.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Talla.swift
//  Textil
//

import SwiftData

@Model
class Talla {

    var nombre: String
    var orden: Int

    init(
        nombre: String = "",
        orden: Int = 0
    ) {
        self.nombre = nombre
        self.orden = orden
    }
}

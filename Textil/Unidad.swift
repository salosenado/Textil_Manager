//
//  Unidad.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Unidad.swift
//  Textil
//

import SwiftData

@Model
class Unidad {

    var nombre: String
    var abreviatura: String
    var factor: Double?

    init(
        nombre: String = "",
        abreviatura: String = "",
        factor: Double? = nil
    ) {
        self.nombre = nombre
        self.abreviatura = abreviatura
        self.factor = factor
    }
}

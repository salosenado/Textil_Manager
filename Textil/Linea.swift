//
//  Linea.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Linea.swift
//  Textil
//

import SwiftData

@Model
class Linea {

    var nombre: String
    var activo: Bool

    init() {
        self.nombre = ""
        self.activo = true
    }
}

//
//  Color.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

//
//  ColorModelo.swift
//  Textil
//

import SwiftData

@Model
class ColorModelo {

    var nombre: String
    var activo: Bool

    init() {
        self.nombre = ""
        self.activo = true
    }
}

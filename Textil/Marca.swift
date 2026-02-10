//
//  Marca.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Marca.swift
//  Textil
//

import SwiftData

@Model
class Marca {

    var nombre: String
    var descripcion: String
    var dueno: String
    var regaliaPorcentaje: String
    var activo: Bool

    init() {
        self.nombre = ""
        self.descripcion = ""
        self.dueno = ""
        self.regaliaPorcentaje = ""
        self.activo = true
    }
}

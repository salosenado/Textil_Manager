//
//  Departamento.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Departamento.swift
//  Textil
//

import SwiftData

@Model
class Departamento {

    var nombre: String
    var descripcion: String
    var activo: Bool

    init() {
        self.nombre = ""
        self.descripcion = ""
        self.activo = true
    }
}

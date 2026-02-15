//
//  ControlDisenoTrazo.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//
import SwiftData
import Foundation

@Model
class ControlDisenoTrazo {

    var ordenNumero: Int
    var modelo: String

    var liberadoDiseno: Bool
    var fechaLiberadoDiseno: Date?

    var liberadoTrazo: Bool
    var fechaLiberadoTrazo: Date?

    init(ordenNumero: Int, modelo: String) {
        self.ordenNumero = ordenNumero
        self.modelo = modelo
        self.liberadoDiseno = false
        self.liberadoTrazo = false
    }
}

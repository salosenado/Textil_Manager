//
//  CostoGeneralEntity.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CostoGeneralEntity.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CostosGeneralListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import Foundation
import SwiftData

@Model
final class CostoGeneralEntity {

    var fecha: Date

    var departamento: Departamento?
    var linea: Linea?

    var modelo: String
    var tallas: String
    var descripcion: String

    @Relationship(deleteRule: .cascade)
    var telas: [CostoGeneralTela]

    @Relationship(deleteRule: .cascade)
    var insumos: [CostoGeneralInsumo]

    init(
        departamento: Departamento?,
        linea: Linea?,
        modelo: String,
        tallas: String,
        descripcion: String,
        fecha: Date = Date()
    ) {
        self.fecha = fecha
        self.departamento = departamento
        self.linea = linea
        self.modelo = modelo
        self.tallas = tallas
        self.descripcion = descripcion
        self.telas = []
        self.insumos = []
    }

    var totalTelas: Double {
        telas.reduce(0) { $0 + $1.total }
    }

    var totalInsumos: Double {
        insumos.reduce(0) { $0 + $1.total }
    }

    var total: Double {
        totalTelas + totalInsumos
    }

    var totalConGastos: Double {
        total * 1.15
    }
}

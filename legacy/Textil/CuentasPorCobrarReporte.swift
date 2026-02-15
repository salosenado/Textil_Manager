//
//  CuentasPorCobrarReporte.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//


import Foundation

struct CuentasPorCobrarReporte {

    var fechaGeneracion: Date
    var cliente: String?
    var fechaInicio: Date?
    var fechaFin: Date?

    var vigente: Double
    var semanaActual: Double
    var semanaSiguiente: Double
    var dias30: Double
    var dias60: Double
    var dias90: Double
    var mas90: Double

    var totalGeneral: Double
}

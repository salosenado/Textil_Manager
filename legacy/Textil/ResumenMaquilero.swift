//
//  ResumenMaquilero.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
import Foundation

struct ResumenMaquilero: Identifiable {
    let id = UUID()

    let maquilero: String
    let ordenesPedidas: Int
    let ordenesEntregadas: Int
    let pzPedidas: Int
    let pzRecibidas: Int
    let pagado: Double
    let pendiente: Double
}

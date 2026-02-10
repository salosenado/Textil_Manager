//
//  ResumenCliente.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//


//
//  ResumenCliente.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//

import Foundation

struct ResumenCliente: Identifiable {

    let id = UUID()

    let proveedor: String
    let ordenes: Int
    let monto: Double
}

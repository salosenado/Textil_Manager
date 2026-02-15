//
//  RegistroLocal.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//


import Foundation

struct RegistroLocal: Codable {

    var empresa: String
    var responsable: String
    var proveedor: String
    var firmaResponsable: Data?
    var firmaProveedor: Data?
}

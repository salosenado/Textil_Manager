//
//  Perfil.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
//
//  Perfil.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//

import Foundation

struct Perfil: Identifiable, Decodable {

    let id: UUID

    let nombre: String?
    let email: String?
    let rol: String

    let aprobado: Bool
    let activo: Bool

    // 🔗 JOIN CON EMPRESAS
    let empresa: EmpresaLite?

    let created_at: Date?
}

//
//  PrivacyPolicyView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//


import SwiftUI

struct PrivacyPolicyView: View {

    var body: some View {
        ScrollView {
            Text("""
POLÍTICA DE PRIVACIDAD

Última actualización: 2026

Esta aplicación recopila información como:
- Nombre
- Correo electrónico
- Identificadores de usuario

La información se utiliza únicamente para:
- Autenticación
- Gestión de cuentas
- Operación interna del sistema

No compartimos información con terceros.

El usuario puede solicitar eliminación de su cuenta desde Ajustes.

Para contacto:
soporte@tuempresa.com
""")
            .padding()
        }
        .navigationTitle("Privacidad")
    }
}

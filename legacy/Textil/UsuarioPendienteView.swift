//
//  UsuarioPendienteView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//


import SwiftUI

struct UsuarioPendienteView: View {

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "clock.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Cuenta pendiente de aprobación")
                .font(.title2)
                .bold()

            Text("""
Tu usuario fue creado correctamente,
pero aún no ha sido aprobado por un administrador.

Te avisaremos cuando esté listo.
""")
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

//
//  UsuarioBloqueadoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//


import SwiftUI

struct UsuarioBloqueadoView: View {

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Usuario desactivado")
                .font(.title)
                .bold()

            Text("Tu cuenta está desactivada.\nContacta al administrador.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

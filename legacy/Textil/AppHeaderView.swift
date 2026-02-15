//
//  AppHeaderView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//


import SwiftUI

struct AppHeaderView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(authVM.perfil?.empresa?.nombre ?? "Sin empresa")
                    .font(.headline)
                Text(authVM.perfil?.rol.capitalized ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

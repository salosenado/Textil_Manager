//
//  LicenciaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//


import SwiftUI

struct LicenciaView: View {

    var body: some View {

        ScrollView {

            VStack(spacing: 25) {

                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)

                Text("Licencia Empresarial")
                    .font(.title)
                    .bold()

                VStack(spacing: 8) {

                    Text("Plan Actual")
                        .font(.headline)

                    Text("Licencia Anual")
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.vertical)

                    Text("Válida hasta:")
                        .font(.headline)

                    Text("31 Diciembre 2026")
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.vertical)

                    Text("Usuarios activos:")
                        .font(.headline)

                    Text("5 usuarios")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )

                Button {
                    // Acción futura renovación
                } label: {
                    Text("Renovar Licencia")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text("© 2026 AppIndustri")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Licencia")
    }
}

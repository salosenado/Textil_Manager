//
//  AjustesView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//

import SwiftUI

struct AjustesView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var mostrarEliminar = false
    @State private var isLoading = false

    var body: some View {

        List {

            Section("Cuenta") {

                Button("Cerrar Sesión") {
                    Task {
                        await authVM.signOut()
                    }
                }

                Button(role: .destructive) {
                    mostrarEliminar = true
                } label: {
                    Text("Eliminar Cuenta")
                }
            }

            Section("Legal") {

                NavigationLink("Política de Privacidad") {
                    PrivacyPolicyView()
                }

                NavigationLink("Términos y Condiciones") {
                    TermsView()
                }
            }

            Section("Información") {
                Text("Versión 1.0")
            }
        }
        .navigationTitle("Ajustes")
        .alert("¿Eliminar cuenta?", isPresented: $mostrarEliminar) {

            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                Task {
                    await authVM.deleteAccount()
                }
            }

        } message: {
            Text("Esta acción eliminará tu cuenta permanentemente.")
        }
    }
}

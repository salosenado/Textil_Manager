//
//  PerfilViewModel.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//


import Foundation
import Supabase
import SwiftUI
import Combine

@MainActor
final class PerfilViewModel: ObservableObject {

    @Published var perfil: Perfil?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func cargarPerfil() async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.session
            let userId = session.user.id

            let response: [Perfil] = try await supabase
                .from("perfiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value

            self.perfil = response.first

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error perfil:", error)
        }

        isLoading = false
    }
}

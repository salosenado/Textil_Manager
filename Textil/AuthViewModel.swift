//
//  AuthViewModel.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
//
//  AuthViewModel.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
//
//  AuthViewModel.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//

import SwiftUI
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {

    // =========================
    // 🔐 ESTADO DE SESIÓN
    // =========================
    @Published var isLoggedIn: Bool = false
    @Published var isCheckingSession: Bool = true

    // =========================
    // 👤 PERFIL / ESTADOS
    // =========================
    @Published var perfil: Perfil?
    @Published var isLoadingPerfil: Bool = false

    @Published var usuarioBloqueado: Bool = false
    @Published var usuarioPendiente: Bool = false   // ⬅️ ESTA ES LA QUE FALTABA

    // =========================
    // INIT
    // =========================
    init() {
        Task {
            await checkSession()
        }
    }

    // =========================
    // 🔐 SESIÓN
    // =========================
    func checkSession() async {
        isCheckingSession = true
        usuarioBloqueado = false
        usuarioPendiente = false

        do {
            _ = try await supabase.auth.session
            await cargarPerfil()

            // 🔒 BLOQUEADO
            if perfil?.activo == false {
                usuarioBloqueado = true
                isLoggedIn = false
            }
            // ⏳ PENDIENTE DE APROBACIÓN
            else if perfil?.aprobado == false {
                usuarioPendiente = true
                isLoggedIn = false
            }
            // ✅ OK
            else {
                isLoggedIn = true
            }

        } catch {
            isLoggedIn = false
            perfil = nil
        }

        isCheckingSession = false
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isLoggedIn = false
        perfil = nil
        usuarioBloqueado = false
        usuarioPendiente = false
    }

    // =========================
    // 👤 PERFIL
    // =========================
    func cargarPerfil() async {
        isLoadingPerfil = true

        do {
            let session = try await supabase.auth.session
            let userId = session.user.id

            let perfiles: [Perfil] = try await supabase
                .from("perfiles")
                .select("""
                    id,
                    nombre,
                    email,
                    rol,
                    aprobado,
                    activo,
                    created_at,
                    empresa:empresas (
                        id,
                        nombre
                    )
                """)
                .eq("id", value: userId)
                .execute()
                .value

            self.perfil = perfiles.first

        } catch {
            print("❌ Error cargando perfil:", error)
            self.perfil = nil
        }

        isLoadingPerfil = false
    }

    // =========================
    // 🔐 HELPERS DE ROL
    // =========================
    var esAdmin: Bool {
        perfil?.rol == "admin" || perfil?.rol == "superadmin"
    }

    var esSuperAdmin: Bool {
        perfil?.rol == "superadmin"
    }
}

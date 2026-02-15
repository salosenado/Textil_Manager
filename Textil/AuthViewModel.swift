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

import SwiftUI
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {

    // =========================
    // 🔐 SESSION STATE
    // =========================
    @Published var isLoggedIn: Bool = false
    @Published var isCheckingSession: Bool = true

    // =========================
    // 👤 PERFIL
    // =========================
    @Published var perfil: Perfil?
    @Published var isLoadingPerfil: Bool = false

    // =========================
    // 🚫 ESTADOS ESPECIALES
    // =========================
    @Published var usuarioBloqueado: Bool = false
    @Published var usuarioPendiente: Bool = false

    // =========================
    // INIT
    // =========================
    init() {
        Task {
            await checkSession()
        }
    }

    // =========================
    // 🔐 CHECK SESSION
    // =========================
    func checkSession() async {

        isCheckingSession = true
        usuarioBloqueado = false
        usuarioPendiente = false

        do {
            let session = try await supabase.auth.session
            let userId = session.user.id

            await cargarPerfil(userId: userId)

            guard let perfil else {
                limpiarSesion()
                isCheckingSession = false
                return
            }

            if perfil.activo == false {
                usuarioBloqueado = true
                isLoggedIn = false
            }
            else if perfil.aprobado == false {
                usuarioPendiente = true
                isLoggedIn = false
            }
            else {
                isLoggedIn = true
            }

        } catch {
            limpiarSesion()
        }

        isCheckingSession = false
    }

    // =========================
    // 🔐 LOGOUT
    // =========================
    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("❌ Error cerrando sesión:", error)
        }

        limpiarSesion()
    }

    // =========================
    // 🗑 ELIMINAR CUENTA
    // =========================
    func deleteAccount() async {
        do {
            // Aquí después podemos agregar endpoint real para borrar usuario
            try await supabase.auth.signOut()
            limpiarSesion()
        } catch {
            print("❌ Error eliminando cuenta:", error)
        }
    }

    // =========================
    // 🧹 LIMPIAR SESIÓN
    // =========================
    private func limpiarSesion() {
        isLoggedIn = false
        perfil = nil
        usuarioBloqueado = false
        usuarioPendiente = false
    }

    // =========================
    // 👤 CARGAR PERFIL
    // =========================
    func cargarPerfil(userId: UUID) async {

        isLoadingPerfil = true

        do {
            let perfil: Perfil = try await supabase
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
                .single()
                .execute()
                .value

            self.perfil = perfil

        } catch {
            print("❌ Error cargando perfil:", error)
            self.perfil = nil
        }

        isLoadingPerfil = false
    }

    // =========================
    // 🔐 ROLES
    // =========================
    var esAdmin: Bool {
        guard let rol = perfil?.rol else { return false }
        return rol == "admin" || rol == "superadmin"
    }

    var esSuperAdmin: Bool {
        perfil?.rol == "superadmin"
    }
}

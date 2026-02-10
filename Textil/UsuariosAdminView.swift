//
//  UsuariosAdminView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
import SwiftUI
import Supabase

// =========================
// 🔧 MODELO UPDATE (ENCODABLE)
// =========================
struct PerfilUpdate: Encodable {
    let aprobado: Bool?
    let activo: Bool?
}

struct UsuariosAdminView: View {

    @State private var usuarios: [Perfil] = []

    var body: some View {
        List {

            ForEach(usuarios) { u in
                VStack(alignment: .leading, spacing: 8) {

                    Text(u.nombre ?? u.email ?? "—")
                        .font(.headline)

                    Text("Rol: \(u.rol)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Aprobado", isOn: Binding(
                        get: { u.aprobado },
                        set: { nuevo in
                            actualizar(u, aprobado: nuevo)
                        }
                    ))

                    Toggle("Activo", isOn: Binding(
                        get: { u.activo },
                        set: { nuevo in
                            actualizar(u, activo: nuevo)
                        }
                    ))
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Usuarios")
        .task {
            await cargarUsuarios()
        }
    }

    // =========================
    // 📥 CARGAR USUARIOS
    // =========================
    func cargarUsuarios() async {
        usuarios = (try? await supabase
            .from("perfiles")
            .select()
            .order("created_at")
            .execute()
            .value) ?? []
    }

    // =========================
    // ✏️ ACTUALIZAR USUARIO
    // =========================
    func actualizar(
        _ perfil: Perfil,
        aprobado: Bool? = nil,
        activo: Bool? = nil
    ) {
        Task {
            let update = PerfilUpdate(
                aprobado: aprobado,
                activo: activo
            )

            try? await supabase
                .from("perfiles")
                .update(update)
                .eq("id", value: perfil.id)
                .execute()

            await cargarUsuarios()
        }
    }
}

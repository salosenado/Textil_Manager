//
//  UsuariosAdminView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
import SwiftUI
import Supabase
import Foundation

// =========================
// 🔧 MODELO UPDATE (ENCODABLE)
// =========================
struct PerfilUpdate: Encodable {
    let aprobado: Bool?
    let activo: Bool?
    let rol: String?
    let empresa_id: UUID?
}

struct UsuariosAdminView: View {

    @State private var usuarios: [Perfil] = []
    @State private var empresas: [EmpresaLite] = []

    var body: some View {
        List {
            ForEach(usuarios) { u in
                VStack(alignment: .leading, spacing: 10) {

                    Text(u.nombre ?? u.email ?? "—")
                        .font(.headline)

                    Picker("Rol", selection: Binding(
                        get: { u.rol },
                        set: { actualizar(u, rol: $0) }
                    )) {
                        Text("Usuario").tag("usuario")
                        Text("Admin").tag("admin")
                        Text("Superadmin").tag("superadmin")
                    }
                    .pickerStyle(.segmented)

                    Picker("Empresa", selection: Binding(
                        get: { u.empresa?.id },
                        set: { actualizar(u, empresaId: $0) }
                    )) {
                        Text("Sin empresa").tag(UUID?.none)
                        ForEach(empresas, id: \.id) {
                            Text($0.nombre).tag(Optional($0.id))
                        }
                    }

                    Toggle("Aprobado", isOn: Binding(
                        get: { u.aprobado },
                        set: { actualizar(u, aprobado: $0) }
                    ))

                    Toggle("Activo", isOn: Binding(
                        get: { u.activo },
                        set: { actualizar(u, activo: $0) }
                    ))
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Usuarios")
        .task {
            await cargarTodo()
        }
    }

    // =========================
    // 📥 CARGAR DATOS
    // =========================
    func cargarTodo() async {
        usuarios = (try? await supabase
            .from("perfiles")
            .select("""
                id,
                nombre,
                email,
                rol,
                aprobado,
                activo,
                empresa:empresas (
                    id,
                    nombre
                )
            """)
            .order("created_at")
            .execute()
            .value) ?? []

        empresas = (try? await supabase
            .from("empresas")
            .select("id, nombre")
            .execute()
            .value) ?? []
    }

    // =========================
    // ✏️ ACTUALIZAR PERFIL
    // =========================
    func actualizar(
        _ perfil: Perfil,
        aprobado: Bool? = nil,
        activo: Bool? = nil,
        rol: String? = nil,
        empresaId: UUID? = nil
    ) {
        Task {
            let update = PerfilUpdate(
                aprobado: aprobado,
                activo: activo,
                rol: rol,
                empresa_id: empresaId
            )

            try? await supabase
                .from("perfiles")
                .update(update)
                .eq("id", value: perfil.id)
                .execute()

            await cargarTodo()
        }
    }
}

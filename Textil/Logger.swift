//
//  Logger.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
import Supabase
import Foundation

// =========================
// 🧾 MODELO LOG
// =========================
struct LogInsert: Encodable {
    let user_id: UUID
    let accion: String
}

// =========================
// 🔔 LOGGER GLOBAL
// =========================
func log(_ accion: String) {
    Task {
        do {
            let session = try await supabase.auth.session

            let nuevoLog = LogInsert(
                user_id: session.user.id,
                accion: accion
            )

            try await supabase
                .from("logs")
                .insert(nuevoLog)
                .execute()

        } catch {
            print("❌ Error guardando log:", error)
        }
    }
}

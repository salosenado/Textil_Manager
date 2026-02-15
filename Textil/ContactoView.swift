//
//  ContactoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//

import SwiftUI

struct ContactoView: View {

    var body: some View {

        ScrollView {
            VStack(spacing: 20) {

                // MARK: - HEADER
                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("AppIndustri")
                        .font(.title)
                        .bold()

                    Text("Soporte Empresarial")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // MARK: - CORREOS
                ContactCard(
                    title: "Ventas",
                    subtitle: "sales@appindustri.com",
                    icon: "briefcase.fill",
                    color: .blue,
                    action: {
                        openURL("mailto:sales@appindustri.com")
                    }
                )

                ContactCard(
                    title: "Soporte Técnico",
                    subtitle: "support@appindustri.com",
                    icon: "headset",
                    color: .green,
                    action: {
                        openURL("mailto:support@appindustri.com")
                    }
                )

                ContactCard(
                    title: "Dirección General",
                    subtitle: "ssenado@appindustri.com",
                    icon: "person.crop.circle.fill",
                    color: .purple,
                    action: {
                        openURL("mailto:ssenado@appindustri.com")
                    }
                )

                // MARK: - WHATSAPP
                ContactCard(
                    title: "WhatsApp Empresarial",
                    subtitle: "55 9101 9101",
                    icon: "message.fill",
                    color: .green,
                    action: {
                        openURL("https://wa.me/5215591019101?text=Hola%20AppIndustri,%20solicito%20información%20sobre%20la%20plataforma.")
                    }
                )

                // MARK: - TELÉFONOS
                ContactCard(
                    title: "Llamar",
                    subtitle: "+52 55 9101 9101",
                    icon: "phone.fill",
                    color: .orange,
                    action: {
                        openURL("tel://5591019101")
                    }
                )

                ContactCard(
                    title: "Llamar",
                    subtitle: "+52 55 5216 2424",
                    icon: "phone.fill",
                    color: .orange,
                    action: {
                        openURL("tel://5552162424")
                    }
                )

                Divider()
                    .padding(.vertical)

                // MARK: - INFO EMPRESA
                VStack(spacing: 6) {
                    Text("México")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Horario: Lunes a Viernes 9:00 – 18:00")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Versión 1.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("© 2026 AppIndustri")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationTitle("Contacto")
    }

    // MARK: - Open URL
    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

struct ContactCard: View {

    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {

        Button(action: action) {
            HStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .bold()
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

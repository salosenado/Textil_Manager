//
//  FirmaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//
import SwiftUI
import Foundation

struct FirmaView: View {

    let titulo: String
    @Binding var firmaData: Data?
    var onSave: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var imagen: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text(titulo)
                    .font(.headline)

                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(height: 220)
                    .overlay(
                        Group {
                            if let imagen {
                                Image(uiImage: imagen)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Text("Aquí va la firma")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    )

                Button("Simular firma") {
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 150))
                    let img = renderer.image { ctx in
                        UIColor.label.setStroke()
                        let path = UIBezierPath()
                        path.move(to: CGPoint(x: 20, y: 80))
                        path.addCurve(
                            to: CGPoint(x: 280, y: 80),
                            controlPoint1: CGPoint(x: 80, y: 20),
                            controlPoint2: CGPoint(x: 200, y: 140)
                        )
                        path.lineWidth = 3
                        path.stroke()
                    }
                    imagen = img
                }

                Spacer()

                Button("Guardar firma") {
                    if let img = imagen,
                       let data = img.pngData() {
                        firmaData = data
                        onSave(data)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

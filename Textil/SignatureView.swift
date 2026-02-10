//
//  SignatureView.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
//
//  SignatureView.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//

import SwiftUI
import UIKit

struct SignatureView: View {

    @Binding var data: Data?

    @State private var points: [CGPoint] = []
    @State private var isDrawing = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white

                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points.first!)
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(.black, lineWidth: 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDrawing {
                            points.removeAll()
                            isDrawing = true
                        }
                        points.append(value.location)
                    }
                    .onEnded { _ in
                        isDrawing = false
                        guardarFirma(size: geo.size)
                    }
            )
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray))
    }

    // =====================================================
    // MARK: - GENERAR PNG
    // =====================================================

    private func guardarFirma(size: CGSize) {
        guard points.count > 1 else { return }

        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: UIGraphicsImageRendererFormat.default()
        )

        let img = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.setLineCap(.round)

            ctx.cgContext.move(to: points.first!)
            for p in points.dropFirst() {
                ctx.cgContext.addLine(to: p)
            }
            ctx.cgContext.strokePath()
        }

        data = img.pngData()
    }
}

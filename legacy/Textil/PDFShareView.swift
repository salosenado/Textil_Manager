//
//  PDFShareView.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//

import SwiftUI

struct PDFShareView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

//
//  ShareSheetView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftUI
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

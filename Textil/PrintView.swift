//
//  PrintView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


import SwiftUI
import UIKit

struct PrintView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()

        DispatchQueue.main.async {
            let printController = UIPrintInteractionController.shared
            printController.printingItem = url
            printController.present(animated: true)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

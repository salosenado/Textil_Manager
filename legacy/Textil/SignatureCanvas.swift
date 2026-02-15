//
//  SignatureCanvas.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//

import UIKit

final class SignatureCanvas: UIView {

    private var path = UIBezierPath()
    private var lastPoint: CGPoint = .zero
    var onFinish: ((UIImage) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        path.lineWidth = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        lastPoint = p
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        path.move(to: lastPoint)
        path.addLine(to: p)
        lastPoint = p
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let img {
            onFinish?(img)
        }
    }

    override func draw(_ rect: CGRect) {
        UIColor.label.setStroke()
        path.stroke()
    }

    func limpiar() {
        path.removeAllPoints()
        setNeedsDisplay()
    }
}

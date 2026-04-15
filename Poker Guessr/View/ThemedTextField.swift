//
//  ThemedTextField.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 05.12.2025.
//


import SwiftUI

struct ThemedTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var textColor: UIColor
    var placeholderColor: UIColor
    var cursorColor: UIColor

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.autocorrectionType = .no
        tf.borderStyle = .none

        // Placeholder Farbe
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor]
        )

        tf.textColor = textColor
        tf.tintColor = cursorColor   // Cursor
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.textColor = textColor
        uiView.tintColor = cursorColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: ThemedTextField
        init(_ parent: ThemedTextField) { self.parent = parent }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}
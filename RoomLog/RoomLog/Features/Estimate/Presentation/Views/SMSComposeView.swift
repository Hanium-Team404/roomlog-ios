//
//  SMSComposeView.swift
//  RoomLog
//
//  Created by 송민교 on 5/13/26.
//

import SwiftUI
import MessageUI
import UIKit

struct SMSComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) { [weak self] in
                self?.onDismiss()
            }
        }
    }

    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }
}

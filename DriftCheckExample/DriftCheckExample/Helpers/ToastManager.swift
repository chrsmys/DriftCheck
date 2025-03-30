//
//  ToastManager.swift
//  RetainCycleDetector
//
//  Created by Chris Mays on 3/25/25.
//

import SwiftUI

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let duration: TimeInterval
}


final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    private var window: UIWindow?
    private var hostingController: UIHostingController<ToastStackView>?

    @Published private(set) var toasts: [Toast] = []

    private init() {
        setupWindow()
    }

    private func setupWindow() {
        let view = ToastStackView(manager: self)
        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .clear

        let window = UIWindow(frame: UIScreen.main.bounds)
        if let windowScene = UIApplication.shared.connectedScenes
                    .filter({ $0.activationState == .foregroundActive })
                    .first as? UIWindowScene {
                    window.windowScene = windowScene
                }
        window.windowLevel = .alert + 1
        window.isHidden = false
        window.isUserInteractionEnabled = false
        window.rootViewController = hosting
        self.window = window
    }

    func show(message: String, duration: TimeInterval = 5.0) {
        let toast = Toast(message: message, duration: duration)
        DispatchQueue.main.async {
            self.toasts.append(toast)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.remove(toast)
        }
    }

    func remove(_ toast: Toast) {
        DispatchQueue.main.async {
            withAnimation {
                self.toasts.removeAll { $0.id == toast.id }
            }
        }
    }
}


struct ToastStackView: View {
    @ObservedObject var manager: ToastManager

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            ForEach(manager.toasts) { toast in
                ToastView(message: toast.message)
                .allowsHitTesting(true)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 16)
        .animation(.spring(), value: manager.toasts)
        .allowsHitTesting(false)
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThickMaterial)
            .cornerRadius(10)
            .shadow(radius: 10)
            .fixedSize(horizontal: false, vertical: true)
         
    }
}


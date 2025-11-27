//
//  ToastView.swift
//  Modaics
//
//  Toast notification system for success/error/info messages
//

import SwiftUI

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toast: Toast?
    
    private init() {}
    
    func show(_ message: String, type: ToastType = .info, duration: Double = 2.0) {
        toast = Toast(message: message, type: type, duration: duration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.toast = nil
            }
        }
    }
    
    func success(_ message: String) {
        show(message, type: .success)
    }
    
    func error(_ message: String) {
        show(message, type: .error)
    }
    
    func info(_ message: String) {
        show(message, type: .info)
    }
}

// MARK: - Toast Model
struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: Double
}

enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .modaicsChrome1
        case .warning: return .orange
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.modaicsCotton)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // Blur effect
                Color.modaicsDarkBlue.opacity(0.95)
                
                // Accent border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [toast.type.color.opacity(0.6), toast.type.color.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: toast.type.color.opacity(0.3),
            radius: 20,
            x: 0,
            y: 10
        )
        .padding(.horizontal, 20)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
            
            HapticManager.shared.notification(toast.type == .success ? .success : 
                                             toast.type == .error ? .error : .warning)
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.2)) {
                offset = -100
                opacity = 0
            }
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = toastManager.toast {
                ToastView(toast: toast)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
    }
}

extension View {
    func withToast() -> some View {
        self.modifier(ToastModifier())
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            Button("Show Success") {
                ToastManager.shared.success("Item added to your wardrobe!")
            }
            .buttonStyle(.bordered)
            
            Button("Show Error") {
                ToastManager.shared.error("Failed to upload image")
            }
            .buttonStyle(.bordered)
            
            Button("Show Info") {
                ToastManager.shared.info("New event near you")
            }
            .buttonStyle(.bordered)
            
            Button("Show Warning") {
                ToastManager.shared.show("Internet connection weak", type: .warning)
            }
            .buttonStyle(.bordered)
        }
    }
    .withToast()
}

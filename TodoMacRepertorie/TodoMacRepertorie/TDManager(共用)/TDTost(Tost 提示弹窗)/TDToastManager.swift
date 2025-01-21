//
//  TDToastManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/8.
//

import Foundation
import SwiftUI
import AlertToast

// MARK: - Toast位置
public enum TDToastPosition {
    case top
    case center
    case bottom
    
    var toAlertToastPosition: AlertToast.DisplayMode {
        switch self {
        case .top:
            return .hud
        case .center:
            return .alert
        case .bottom:
            return .banner(.pop)
        }
    }
}

// MARK: - Toast类型
public enum TDToastType {
    case regular
    case success
    case error
    case info
    
    var toAlertType: AlertToast.AlertType {
        switch self {
        case .regular:
            return .regular
        case .success:
            return .complete(.green)
        case .error:
            return .error(.red)
        case .info:
            return .regular
        }
    }
}

public extension View {
    func tdToast(
        isPresenting: Binding<Bool>,
        message: String,
        type: TDToastType = .regular,
        position: TDToastPosition = .bottom
    ) -> some View {
        self.toast(isPresenting: isPresenting) {
            AlertToast(
                displayMode: position.toAlertToastPosition,
                type: type.toAlertType,
                title: "Todo清单：\(message)"
            )
        }
    }
    
    // 顶部显示
    func tdToastTop(
        isPresenting: Binding<Bool>,
        message: String,
        type: TDToastType = .regular
    ) -> some View {
        tdToast(
            isPresenting: isPresenting,
            message: message,
            type: type,
            position: .top
        )
    }
    
    // 中间显示
    func tdToastCenter(
        isPresenting: Binding<Bool>,
        message: String,
        type: TDToastType = .regular
    ) -> some View {
        tdToast(
            isPresenting: isPresenting,
            message: message,
            type: type,
            position: .center
        )
    }
    
    // 底部显示
    func tdToastBottom(
        isPresenting: Binding<Bool>,
        message: String,
        type: TDToastType = .regular
    ) -> some View {
        tdToast(
            isPresenting: isPresenting,
            message: message,
            type: type,
            position: .bottom
        )
    }
}



//
//// MARK: - Toast类型枚举
//enum TDToastType {
//    case success
//    case error
//    case info
//    case regular
//    
//    var iconName: String {
//        switch self {
//        case .success:
//            return "checkmark.circle.fill"
//        case .error:
//            return "xmark.circle.fill"
//        case .info:
//            return "info.circle.fill"
//        case .regular:
//            return ""
//        }
//    }
//    
//    var tintColor: Color {
//        switch self {
//        case .success:
//            return .green
//        case .error:
//            return .red
//        case .info:
//            return .blue
//        case .regular:
//            return .primary
//        }
//    }
//}
//
//// MARK: - Toast位置
//enum TDToastPosition {
//    case topCenter      // 顶部中间
//    case bottomCenter   // 底部中间
//    case bottomRight    // 右下角
//    case center        // 正中间
//    case custom(anchor: UnitPoint, offset: CGPoint) // 自定义位置
//}
//
//// MARK: - Toast内容 底部中间 不显示图片
//struct TDToast {
//    var type: TDToastType = .regular
//    var title: String
//    var subTitle: String? = nil
//    var position: TDToastPosition = .bottomCenter
//    var showIcon: Bool = false
//}
//
//
//// MARK: - Toast视图
//struct TDToastView: View {
//    let toast: TDToast
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            if toast.showIcon && toast.type != .regular {
//                Image(systemName: toast.type.iconName)
//                    .foregroundColor(toast.type.tintColor)
//            }
//            
//            VStack(spacing: 4) {
//                Text("Todo清单：" + toast.title)
//                    .font(.system(size: 14))
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                
//                if let subTitle = toast.subTitle {
//                    Text(subTitle)
//                        .font(.system(size: 12))
//                        .foregroundColor(.white.opacity(0.8))
//                        .multilineTextAlignment(.center)
//                }
//            }
//        }
//        .frame(maxWidth: 300)
//        .padding(.horizontal, 16)
//        .padding(.vertical, 10)
//        .background(Color.black.opacity(0.7))
//        .cornerRadius(20)
//        .shadow(radius: 4)
//    }
//}
//
//// MARK: - Toast修饰器
//struct TDToastModifier: ViewModifier {
//    @Binding var isPresented: Bool
//    let toast: TDToast
//    
//    func body(content: Content) -> some View {
//        ZStack {
//            content
//            
//            GeometryReader { geometry in
//                if isPresented {
//                    TDToastView(toast: toast)
//                        .position(position(in: geometry))
//                        .transition(transition(for: toast.position))
//                        .animation(.spring(), value: isPresented)
//                        .onAppear {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                                withAnimation {
//                                    isPresented = false
//                                }
//                            }
//                        }
//                }
//            }
//        }
//    }
//    
//    private func transition(for position: TDToastPosition) -> AnyTransition {
//        switch position {
//        case .topCenter:
//            return .move(edge: .top).combined(with: .opacity)
//        case .bottomCenter, .bottomRight:
//            return .move(edge: .bottom).combined(with: .opacity)
//        case .center, .custom:
//            return .opacity
//        }
//    }
//    
//    private func position(in geometry: GeometryProxy) -> CGPoint {
//        let size = geometry.size
//        
//        switch toast.position {
//        case .topCenter:
//            return CGPoint(x: size.width / 2, y: 30)
//        case .bottomCenter:
//            return CGPoint(x: size.width / 2, y: size.height - 30)
//        case .bottomRight:
//            return CGPoint(x: size.width - 30, y: size.height - 30)
//        case .center:
//            return CGPoint(x: size.width / 2, y: size.height / 2)
//        case .custom(let anchor, let offset):
//            let x = size.width * anchor.x + offset.x
//            let y = size.height * anchor.y + offset.y
//            return CGPoint(x: x, y: y)
//        }
//    }
//}
//
//// MARK: - View扩展
//extension View {
//    // 基础方法
//    func tdToast(isPresenting: Binding<Bool>, toast: TDToast) -> some View {
//        modifier(TDToastModifier(isPresented: isPresenting, toast: toast))
//    }
//    
//    func tdToast(isPresenting: Binding<Bool>, title: String, type: TDToastType = .regular, position: TDToastPosition = .bottomCenter) -> some View {
//        modifier(TDToastModifier(
//            isPresented: isPresenting,
//            toast: TDToast(
//                type: type,
//                title: title,
//                position: position
//            )
//        ))
//    }
//    
//    // MARK: - 顶部中间
//    func tdToastTop(isPresenting: Binding<Bool>, title: String, type: TDToastType = .regular) -> some View {
//        tdToast(isPresenting: isPresenting, title: title, type: type, position: .topCenter)
//    }
//    
//    // MARK: - 底部中间
//    func tdToastBottom(isPresenting: Binding<Bool>, title: String, type: TDToastType = .regular) -> some View {
//        tdToast(isPresenting: isPresenting, title: title, type: type, position: .bottomCenter)
//    }
//    
//    // MARK: - 右下角
//    func tdToastBottomRight(isPresenting: Binding<Bool>, title: String, type: TDToastType = .regular) -> some View {
//        tdToast(isPresenting: isPresenting, title: title, type: type, position: .bottomRight)
//    }
//    
//    // MARK: - 正中间
//    func tdToastCenter(isPresenting: Binding<Bool>, title: String, type: TDToastType = .regular) -> some View {
//        tdToast(isPresenting: isPresenting, title: title, type: type, position: .center)
//    }
//    
//    // MARK: - 带子标题的便捷方法
//    func tdToastWithSubTitle(
//        isPresenting: Binding<Bool>,
//        title: String,
//        subTitle: String,
//        type: TDToastType = .regular,
//        position: TDToastPosition = .bottomCenter
//    ) -> some View {
//        tdToast(isPresenting: isPresenting, toast: TDToast(
//            type: type,
//            title: title,
//            subTitle: subTitle,
//            position: position
//        ))
//    }
//}

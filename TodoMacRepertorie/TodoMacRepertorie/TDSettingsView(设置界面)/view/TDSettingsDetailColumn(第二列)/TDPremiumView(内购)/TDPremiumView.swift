//
//  TDPremiumView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/5/11.
//
//  设置 → 高级会员：展示商品列表、发起购买、恢复购买
//

import SwiftUI
import StoreKit

struct TDPremiumView: View {

    // MARK: - 环境依赖
    @EnvironmentObject private var themeManager: TDThemeManager
    @ObservedObject private var userManager  = TDUserManager.shared
    @ObservedObject private var iapManager   = TDIAPManager.shared

    // MARK: - 本地状态
    /// 当前选中的商品 ID
    @State private var selectedProductID: String?
    /// 是否展示错误 Alert
    @State private var showErrorAlert = false
    /// 错误信息
    @State private var errorMessage = ""
    /// 是否展示购买成功 Alert
    @State private var showSuccessAlert = false
    /// 成功提示文案
    @State private var successMessage = ""
    /// 是否展示恢复购买成功 Alert
    @State private var showRestoreAlert = false

    // MARK: - 计算属性

    /// 用户当前是否是 VIP
    private var isVIP: Bool { userManager.isVIP }

    /// 当前购买是否正在进行中（任意 loading 状态）
    private var isBusy: Bool {
        switch iapManager.purchaseState {
        case .idle, .success, .failed: return false
        default: return true
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── 顶部 VIP 状态横幅 ──
                vipStatusBanner
                    .padding(.horizontal, 18)
                    .padding(.top, 22)
                    .padding(.bottom, 20)

                // ── 会员权益说明 ──
                benefitsSection
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)

                // ── 商品列表 ──
                productsSection
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)

                // ── 购买 & 恢复购买按钮 ──
                actionButtons
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)

                // ── 免责说明 ──
                legalNote
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
            }
        }
        .background(themeManager.secondaryBackgroundColor)
        .task {
            // 页面出现时自动加载商品列表
            await iapManager.loadProducts()
            // 默认选中第一个商品
            if selectedProductID == nil {
                selectedProductID = iapManager.products.first?.id
            }
        }
        // 监听购买成功通知
        .onReceive(NotificationCenter.default.publisher(for: .tdIAPPurchaseSuccess)) { notification in
            let productID = notification.object as? String ?? ""
            successMessage = buildSuccessMessage(for: productID)
            showSuccessAlert = true
        }
        // 监听 purchaseState 变化以展示错误
        .onChange(of: iapManager.purchaseState) { _, newState in
            if case .failed(let msg) = newState {
                errorMessage = msg
                showErrorAlert = true
            }
        }
        // 购买失败 Alert
        .alert("购买失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {
                iapManager.purchaseState = .idle
            }
        } message: {
            Text(errorMessage)
        }
        // 购买成功 Alert
        .alert("购买成功 🎉", isPresented: $showSuccessAlert) {
            Button("太棒了") {
                iapManager.purchaseState = .idle
            }
        } message: {
            Text(successMessage)
        }
        // 恢复购买成功 Alert
        .alert("恢复成功", isPresented: $showRestoreAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("已成功恢复您的购买记录，会员权益已生效。")
        }
    }

    // MARK: - 子视图

    // ── VIP 状态横幅 ──────────────────────────────────────────────
    @ViewBuilder
    private var vipStatusBanner: some View {
        HStack(spacing: 14) {
            // 皇冠图标
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isVIP
                          ? LinearGradient(colors: [Color.fromHex("#FFD700"), Color.fromHex("#FFA500")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [themeManager.color(level: 4), themeManager.color(level: 6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(isVIP ? "当前已是高级会员" : "开通高级会员")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                Text(isVIP
                     ? "到期时间：\(vipDeadlineText)"
                     : "解锁全部功能，畅享 Todo 清单高级体验")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                // 亮色模式 alpha≈0.6（#99），暗色模式 alpha≈0.08（#14），使用 8 位 hex AARRGGBB 格式
                .fill(isVIP
                      ? Color.adaptive(light: "#99FFF8E1", dark: "#14FFF8E1")
                      : themeManager.backgroundColor)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                // alpha≈0.4（#66）
                .stroke(isVIP ? Color.fromHex("#66FFD700") : themeManager.borderColor.opacity(0.2),
                        lineWidth: 1)
        )
    }

    /// VIP 到期时间格式化文本
    private var vipDeadlineText: String {
        guard let user = userManager.currentUser else { return "未知" }
        let deadline = user.vipDeadTime
        if deadline <= 0 { return "长期有效" }
        let date = Date(timeIntervalSince1970: TimeInterval(deadline) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // ── 会员权益列表 ──────────────────────────────────────────────
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("会员专属权益")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.descriptionTextColor)
                .padding(.bottom, 2)

            let benefits: [(icon: String, title: String, desc: String)] = [
                ("paintpalette.fill",      "专属主题皮肤",   "解锁全部个性化主题配色"),
                ("wand.and.stars",          "智能功能模块",   "解锁高级功能与实用插件"),
                ("icloud.and.arrow.up",     "多端数据同步",   "手机与 Mac 无缝互联"),
                ("app.badge",               "专属应用图标",   "多款精美图标随心切换"),
                ("calendar.badge.checkmark","高级日程管理",   "解锁日历与日程深度集成"),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(benefits, id: \.title) { item in
                    TDPremiumBenefitRow(
                        icon: item.icon,
                        title: item.title,
                        desc: item.desc,
                        themeManager: themeManager
                    )
                }
            }
        }
    }

    // ── 商品列表 ──────────────────────────────────────────────────
    @ViewBuilder
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择套餐")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.descriptionTextColor)
                .padding(.bottom, 2)

            if case .loadingProducts = iapManager.purchaseState {
                // 加载中骨架
                ForEach(0..<4, id: \.self) { _ in
                    TDPremiumProductSkeleton(themeManager: themeManager)
                }
            } else if iapManager.products.isEmpty {
                // 商品为空（加载失败）
                TDPremiumEmptyProducts(themeManager: themeManager) {
                    Task { await iapManager.loadProducts() }
                }
            } else {
                // 商品卡片列表
                ForEach(iapManager.products, id: \.id) { product in
                    TDPremiumProductCard(
                        product: product,
                        priceText: product.displayPrice,
                        isSelected: selectedProductID == product.id,
                        isPurchased: iapManager.isPurchased(product.id),
                        themeManager: themeManager
                    ) {
                        selectedProductID = product.id
                    }
                }
            }
        }
    }

    // ── 操作按钮 ──────────────────────────────────────────────────
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // 主按钮：立即购买
            Button(action: handlePurchase) {
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.75)
                            .tint(.white)
                    }
                    Text(purchaseButtonTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isBusy || selectedProductID == nil
                              ? themeManager.color(level: 4).opacity(0.5)
                              : themeManager.color(level: 5))
                )
            }
            .buttonStyle(.plain)
            .disabled(isBusy || selectedProductID == nil || iapManager.products.isEmpty)

            // 恢复购买按钮（文字按钮）
            Button(action: handleRestorePurchases) {
                Text(iapManager.purchaseState == .restoring ? "恢复中..." : "恢复购买")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.color(level: 5))
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
        }
    }

    // ── 底部免责说明 ───────────────────────────────────────────────
    private var legalNote: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("购买后永久有效，不会自动扣费。如需退款请通过 Apple 官方渠道申请。")
                .font(.system(size: 11))
                .foregroundColor(themeManager.descriptionTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
            HStack(spacing: 4) {
                Link("用户协议", destination: URL(string: "https://www.evestudio.cn/todoList/agreement")!)
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.color(level: 5))
                Text("·")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.descriptionTextColor.opacity(0.5))
                Link("隐私政策", destination: URL(string: "https://www.evestudio.cn/todoList/privacy")!)
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.color(level: 5))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 计算属性

    private var purchaseButtonTitle: String {
        switch iapManager.purchaseState {
        case .loadingProducts:
            return "加载商品中..."
        case .purchasing:
            return "支付中..."
        case .verifying:
            return "校验中..."
        case .restoring:
            return "恢复中..."
        default:
            if let id = selectedProductID,
               let product = iapManager.products.first(where: { $0.id == id }) {
                return "立即购买 \(product.displayPrice)"
            }
            return "立即购买"
        }
    }

    // MARK: - 事件处理

    /// 发起购买
    private func handlePurchase() {
        guard let productID = selectedProductID,
              let product = iapManager.products.first(where: { $0.id == productID }) else {
            return
        }
        Task {
            do {
                try await iapManager.purchase(product)
            } catch let error as TDIAPError {
                // userCancelled / purchasePending 不弹错误提示
                switch error {
                case .userCancelled, .purchasePending:
                    break
                default:
                    errorMessage = error.errorDescription ?? "购买失败"
                    showErrorAlert = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    /// 恢复购买
    private func handleRestorePurchases() {
        Task {
            do {
                try await iapManager.restorePurchases()
                showRestoreAlert = true
            } catch let error as TDIAPError {
                if case .nothingToRestore = error {
                    errorMessage = "未找到可恢复的购买记录"
                } else {
                    errorMessage = error.errorDescription ?? "恢复失败"
                }
                showErrorAlert = true
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    /// 根据产品 ID 生成购买成功文案
    private func buildSuccessMessage(for productID: String) -> String {
        guard let type = TDIAPProductID(rawValue: productID) else {
            return "购买成功！高级会员权益已生效，感谢您的支持。"
        }
        switch type {
        case .month12:
            return "月度会员购买成功！本月内尽享全部高级权益。"
        case .quarter40:
            return "季度会员购买成功！三个月内尽享全部高级权益。"
        case .year118:
            return "年度会员购买成功！一整年尽享全部高级权益。"
        case .forever168:
            return "永久会员购买成功！一次购买，永久享用全部高级权益。"
        case .yearUpdate:
            return "年度升级成功！您已升级为年度高级会员，感谢支持。"
        }
    }
}

// MARK: - 子组件：权益行

private struct TDPremiumBenefitRow: View {
    let icon: String
    let title: String
    let desc: String
    let themeManager: TDThemeManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.color(level: 5))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(themeManager.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(themeManager.borderColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - 子组件：商品卡片

private struct TDPremiumProductCard: View {
    let product: Product
    /// 已格式化的人民币价格字符串，由父视图传入（如 ¥12）
    let priceText: String
    let isSelected: Bool
    let isPurchased: Bool
    let themeManager: TDThemeManager
    let onTap: () -> Void

    /// 根据产品 ID 给出中文描述标签（如"热门"、"推荐"）
    private var tag: String? {
        switch product.id {
        case TDIAPProductID.year118.rawValue:    return "推荐"
        case TDIAPProductID.forever168.rawValue: return "买断"
        default: return nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 选中指示器
                ZStack {
                    Circle()
                        .stroke(isSelected ? themeManager.color(level: 5) : themeManager.borderColor.opacity(0.4),
                                lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 18, height: 18)
                    if isSelected {
                        Circle()
                            .fill(themeManager.color(level: 5))
                            .frame(width: 10, height: 10)
                    }
                }

                // 商品信息
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.titleTextColor)
                        // 标签徽章
                        if let tag {
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(themeManager.color(level: 5))
                                )
                        }
                        // 已购标签
                        if isPurchased {
                            Text("已购")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(themeManager.color(level: 5))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(themeManager.color(level: 2).opacity(0.3))
                                )
                        }
                    }
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // 价格
                Text(priceText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? themeManager.color(level: 5) : themeManager.titleTextColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected
                          ? themeManager.color(level: 2).opacity(0.18)
                          : themeManager.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? themeManager.color(level: 5) : themeManager.borderColor.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 子组件：骨架屏

private struct TDPremiumProductSkeleton: View {
    let themeManager: TDThemeManager
    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(themeManager.borderColor.opacity(shimmer ? 0.12 : 0.06))
            .frame(height: 56)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    shimmer = true
                }
            }
    }
}

// MARK: - 子组件：商品列表为空

private struct TDPremiumEmptyProducts: View {
    let themeManager: TDThemeManager
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(themeManager.descriptionTextColor.opacity(0.5))
            Text("商品加载失败，请检查网络后重试")
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
            Button("重新加载", action: onRetry)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.color(level: 5))
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Preview

#Preview {
    TDPremiumView()
        .environmentObject(TDThemeManager.shared)
        .frame(width: 520, height: 750)
}

//
//  TDIAPManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/5/11.
//
//  职责：Mac App Store 内购全生命周期管理（基于 StoreKit 2）
//  当前支持：非消耗型一次性购买（月/季/年/永久/升级包）
//  预留扩展：后续接入自动续期订阅时，在标有 [订阅扩展] 注释处补充对应逻辑即可
//

import Foundation
import StoreKit
import OSLog

@MainActor
final class TDIAPManager: ObservableObject {

    // MARK: - 单例
    static let shared = TDIAPManager()

    // MARK: - 日志
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDIAPManager")

    // MARK: - Published 属性（UI 直接绑定）

    /// 从 App Store 拉取到的商品列表（按价格升序排列）
    @Published private(set) var products: [Product] = []

    /// 当前已购买且未被撤销的产品 ID 集合
    /// - 一次性购买：购买后永久存在（除非退款被苹果撤销）
    /// - [订阅扩展] 自动续期订阅：StoreKit 2 会自动只保留有效期内的交易，无需额外过滤
    @Published private(set) var purchasedProductIDs: Set<String> = []

    /// 当前购买流程状态
    @Published var purchaseState: TDIAPPurchaseState = .idle

    /// 商品列表是否加载完成
    @Published private(set) var isProductsLoaded = false

    // MARK: - 私有属性

    /// 后台事务监听任务（App 存活期间一直运行）
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - 初始化

    private init() {
        // 启动事务监听（必须在 App 启动时立即开始，避免遗漏未处理的交易）
        transactionListenerTask = startTransactionListener()
        // 初始化时同步一次本地权益状态
        Task { await refreshPurchasedStatus() }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - 公开方法

    // ─────────────────────────────────────────────────────────────
    // 1. 加载商品列表
    // ─────────────────────────────────────────────────────────────

    /// 向 App Store 请求内购商品列表
    /// - 调用时机：VIP 页面首次出现，或用户手动刷新
    func loadProducts() async {
        guard !isProductsLoaded || products.isEmpty else { return }

        purchaseState = .loadingProducts
        os_log(.info, log: logger, "📦 开始请求商品列表...")

        do {
            // 向 StoreKit 请求所有定义的产品 ID
            let storeProducts = try await Product.products(for: TDIAPProductID.allIDs)

            // 按价格升序排列，方便 UI 从低到高展示
            products = storeProducts.sorted { $0.price < $1.price }
            isProductsLoaded = true
            purchaseState = .idle
            os_log(.info, log: logger, "✅ 商品列表加载成功，共 %d 个", products.count)
        } catch {
            purchaseState = .failed("商品列表加载失败：\(error.localizedDescription)")
            os_log(.error, log: logger, "❌ 商品列表加载失败：%@", error.localizedDescription)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 2. 发起购买
    // ─────────────────────────────────────────────────────────────

    /// 购买指定商品
    /// - Parameter product: 要购买的 StoreKit Product 对象
    /// - Throws: TDIAPError
    func purchase(_ product: Product) async throws {
        // 2-1. 必须登录
        guard TDUserManager.shared.isUserLoggedIn else {
            throw TDIAPError.notLoggedIn
        }

        // 2-2. 设备是否支持内购
        guard AppStore.canMakePayments else {
            throw TDIAPError.purchaseNotAllowed
        }

        // 2-3. 更新状态为"购买中"
        purchaseState = .purchasing(productID: product.id)
        os_log(.info, log: logger, "🛒 开始购买：%@", product.id)

        do {
            // 2-4. 调用 StoreKit 2 purchase API
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                // 2-5. 验证苹果签名（本地验签）
                try await handleVerifiedTransaction(verificationResult, productID: product.id)

            case .userCancelled:
                // 用户主动取消，不算错误，静默重置状态
                purchaseState = .idle
                os_log(.info, log: logger, "🚫 用户取消购买：%@", product.id)
                throw TDIAPError.userCancelled

            case .pending:
                // 等待审批（如家长控制）
                purchaseState = .idle
                os_log(.info, log: logger, "⏳ 购买等待审批：%@", product.id)
                throw TDIAPError.purchasePending

            @unknown default:
                purchaseState = .failed("未知的购买结果")
                throw TDIAPError.unknownPurchaseResult
            }
        } catch let iapError as TDIAPError {
            // 已分类的内购错误直接往上抛
            throw iapError
        } catch {
            // StoreKit 原始错误
            let msg = error.localizedDescription
            purchaseState = .failed(msg)
            os_log(.error, log: logger, "❌ 购买失败：%@", msg)
            throw TDIAPError.other(error)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 3. 恢复购买
    // ─────────────────────────────────────────────────────────────

    /// 恢复当前 Apple ID 的历史购买记录
    /// - 适用场景：用户换设备 / 重装 App 后找回 VIP 权益
    func restorePurchases() async throws {
        purchaseState = .restoring
        os_log(.info, log: logger, "🔄 开始恢复购买...")

        // StoreKit 2：同步 App Store 上的所有交易
        try await AppStore.sync()

        // 刷新本地权益状态
        await refreshPurchasedStatus()

        if purchasedProductIDs.isEmpty {
            purchaseState = .idle
            os_log(.info, log: logger, "ℹ️ 恢复购买完成，未找到可恢复的项目")
            throw TDIAPError.nothingToRestore
        } else {
            purchaseState = .success
            os_log(.info, log: logger, "✅ 恢复购买成功，已购产品：%@", purchasedProductIDs.description)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 4. 检查指定商品是否已购买
    // ─────────────────────────────────────────────────────────────

    /// 查询某个产品 ID 是否已购买且未被撤销
    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    /// 刷新本地已购状态（遍历 StoreKit 2 当前所有有效权益）
    /// - 一次性购买：未被撤销（退款）的交易始终有效
    /// - [订阅扩展] 自动续期订阅：StoreKit 2 的 currentEntitlements 只返回当前有效期内的订阅，
    ///   无需在此处额外判断是否过期，框架已自动处理
    func refreshPurchasedStatus() async {
        var validIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            // 未被苹果撤销（退款/家长控制移除）则视为有效
            if transaction.revocationDate == nil {
                validIDs.insert(transaction.productID)
            }
        }

        purchasedProductIDs = validIDs
        os_log(.debug, log: logger, "🔍 本地权益刷新完成：%@", validIDs.description)
    }

    // MARK: - 私有方法

    // ─────────────────────────────────────────────────────────────
    // 5. 处理已通过苹果签名验证的交易
    // ─────────────────────────────────────────────────────────────

    private func handleVerifiedTransaction(
        _ verificationResult: VerificationResult<Transaction>,
        productID: String
    ) async throws {
        // 5-1. 在解包前先取出 JWS 原文（jwsRepresentation 在 VerificationResult 上）
        let jws = verificationResult.jwsRepresentation

        // 5-2. 本地验签（检查 JWS 签名是否为苹果签发）
        let transaction: Transaction
        switch verificationResult {
        case .verified(let t):
            transaction = t
        case .unverified(_, let error):
            // 苹果签名校验失败（可能是伪造交易）
            let msg = "苹果本地签名校验失败：\(error.localizedDescription)"
            purchaseState = .failed(msg)
            os_log(.error, log: logger, "❌ %@", msg)
            throw TDIAPError.verificationFailed(msg)
        }

        // 5-3. 进入服务端校验阶段
        purchaseState = .verifying
        os_log(.info, log: logger, "🔐 开始服务端校验，transactionID：%llu", transaction.id)

        do {
            let userId = TDUserManager.shared.userId
            // 发送给自有服务器校验（见 TDIAPVerifyAPI）
            try await TDIAPVerifyAPI.shared.verifyTransaction(transaction,
                                                              jwsRepresentation: jws,
                                                              userId: userId)

            // 5-3. 校验成功：结束交易 + 更新本地状态 + 更新用户 VIP
            await transaction.finish()
            await refreshPurchasedStatus()
            updateUserVIPStatus(isVIP: true)
            purchaseState = .success
            os_log(.info, log: logger, "🎉 购买成功并校验通过：%@", productID)

            // 发送购买成功通知（其他模块可监听以刷新 UI）
            NotificationCenter.default.post(name: .tdIAPPurchaseSuccess, object: productID)

        } catch {
            // 5-4. 服务端校验失败：不结束交易（下次启动重试），提示用户
            let msg: String
            if let netErr = error as? TDNetworkError {
                msg = netErr.errorMessage
            } else {
                msg = error.localizedDescription
            }
            purchaseState = .failed(msg)
            os_log(.error, log: logger, "❌ 服务端校验失败：%@", msg)
            throw TDIAPError.verificationFailed(msg)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 6. 后台事务监听（处理 App 外完成的交易）
    // ─────────────────────────────────────────────────────────────
    // 一次性购买场景：家长审批通过、苹果退款撤销
    // [订阅扩展] 自动续期订阅场景：还需在此处处理续费成功事件

    private func startTransactionListener() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            // Transaction.updates 持续输出所有新交易（退款撤销 / 家长审批通过 / [订阅扩展] 续费）
            for await result in Transaction.updates {
                guard let self else { break }
                await self.handleBackgroundTransaction(result)
            }
        }
    }

    private func handleBackgroundTransaction(_ result: VerificationResult<Transaction>) async {
        // 在 switch 解包前先取出 JWS 原文
        let jws = result.jwsRepresentation

        switch result {
        case .verified(let transaction):
            os_log(.info, log: logger, "📬 后台收到新交易：%@ (%llu)", transaction.productID, transaction.id)

            if transaction.revocationDate != nil {
                // 交易被苹果撤销（退款）→ 刷新权益，同步 VIP 状态
                await refreshPurchasedStatus()
                let stillVIP = !purchasedProductIDs.isEmpty
                updateUserVIPStatus(isVIP: stillVIP)
                os_log(.info, log: logger, "⚠️ 交易被撤销（退款）：%@", transaction.productID)
            } else {
                // 正常新交易（家长审批通过 / [订阅扩展] 续费）→ 服务端校验
                do {
                    let userId = TDUserManager.shared.userId
                    try await TDIAPVerifyAPI.shared.verifyTransaction(transaction,
                                                                      jwsRepresentation: jws,
                                                                      userId: userId)
                    await transaction.finish()
                    await refreshPurchasedStatus()
                    updateUserVIPStatus(isVIP: true)
                    os_log(.info, log: logger, "✅ 后台交易校验成功：%@", transaction.productID)
                    NotificationCenter.default.post(name: .tdIAPPurchaseSuccess, object: transaction.productID)
                } catch {
                    // 校验失败暂不 finish，等下次 App 启动重试
                    os_log(.error, log: logger, "❌ 后台交易服务端校验失败：%@", error.localizedDescription)
                }
            }

        case .unverified(let transaction, let error):
            // 苹果签名校验失败，finish 掉防止重复触发
            await transaction.finish()
            os_log(.error, log: logger, "❌ 后台交易签名验证失败：%@ | 错误：%@",
                   transaction.productID, error.localizedDescription)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 7. 更新本地用户 VIP 状态
    // ─────────────────────────────────────────────────────────────

    /// 购买/恢复成功后，将本地 TDUserModel 的 vip 字段同步更新
    private func updateUserVIPStatus(isVIP: Bool) {
        guard var user = TDUserManager.shared.currentUser else { return }
        // 只有状态真正改变才更新，避免不必要的写入
        guard user.vip != isVIP else { return }
        user.vip = isVIP
        // 如果开通 VIP，将过期时间设为一个较远的未来（由服务端返回的真实时间以服务端为准）
        // 这里仅做乐观更新，下次登录会从服务端同步准确数据
        TDUserManager.shared.updateUserInfo(user)
        os_log(.info, log: logger, "👑 本地 VIP 状态已更新：%@", isVIP ? "是" : "否")
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    /// 内购成功通知（object 为购买的产品 ID String）
    static let tdIAPPurchaseSuccess = Notification.Name("tdIAPPurchaseSuccess")
}

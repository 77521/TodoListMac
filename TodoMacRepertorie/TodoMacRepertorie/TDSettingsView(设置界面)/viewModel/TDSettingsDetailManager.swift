//
//  TDSettingsDetailManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/18.
//

import Foundation
import PhotosUI
import AppKit
import _PhotosUI_SwiftUI

/// 管理不同设置页面的卡片数据构建，基于左侧选中的 `TDSettingItemID`。
final class TDSettingsDetailManager {
    static let shared = TDSettingsDetailManager()
    private init() {}
    
    // 账号更改错误分发，用于对应输入框显示
    enum TDAccountChangeFlowError: Error {
        case password(String)
        case smsCode(String)
        case oldEmailCode(String)
        case newEmailCode(String)
        case email(String)
        case general(String)
    }

    
    struct TDAccountContext {
        let nickname: String
        let phone: String
        let account: String
        let hasAccount: Bool
        let isWechatBound: Bool
        let isQQBound: Bool
        let isAppleIDBound: Bool
    }
    
    /// 根据左侧选项返回对应的卡片列表。需要的上下文按页面定义传入。
    func cards(for id: TDSettingItemID,
               account: TDAccountContext? = nil) -> [TDSettingsCardModel] {
        switch id {
        case .accountSecurity:
            guard let account else { return [] }
            return accountSecurityCards(account)
        // 其他页面在此扩展，例如：
        // case .general: return generalCards(generalContext)
        default:
            return []
        }
    }
    
    // 便捷方法：账号安全卡片（直接传入字段）
    func accountSecurityCards(nickname: String,
                              phone: String,
                              account: String,
                              hasAccount: Bool,
                              isWechatBound: Bool,
                              isQQBound: Bool,
                              isAppleIDBound: Bool) -> [TDSettingsCardModel] {
        let ctx = TDAccountContext(
            nickname: nickname,
            phone: phone,
            account: account,
            hasAccount: hasAccount,
            isWechatBound: isWechatBound,
            isQQBound: isQQBound,
            isAppleIDBound: isAppleIDBound
        )
        return accountSecurityCards(ctx)
    }

    
    
    /// 更新用户信息：昵称/头像/性别（调用 editUser，并回写本地用户模型）
    @MainActor
    func updateUserProfile(userManager: TDUserModel) async throws {
        // 本地校验：昵称长度
        if userManager.userName.count > 15 {
            TDToastCenter.shared.td_settingShow("settings.account.nickname.too_long".localized)
            return
        }

        do {
            _ = try await TDSettingAPI.shared.editUser(
                nickname: userManager.userName,
                head: userManager.head,
                sex: userManager.sex
            )
            TDUserManager.shared.updateUserInfo(userManager)
            TDToastCenter.shared.td_settingShow("settings.account.nickname.update.success".localized, type: .success)
        } catch {
            // 显示接口返回/系统错误文案
            TDToastCenter.shared.td_settingShow(error.localizedDescription, type: .error)
            throw error
        }

    }
    
    /// 退出登录
    @MainActor
    func logout() async {
        do {
            _ = try await TDSettingAPI.shared.logout()
            TDUserManager.shared.logoutCurrentUser()
//            TDToastCenter.shared.td_settingShow("settings.logout.success".localized, type: .success)
            TDSettingsWindowTracker.shared.closeSettingsWindow()
        } catch {
            TDToastCenter.shared.td_settingShow(error.localizedDescription, type: .error)
        }
    }
    
    /// 注销账号
    /// - Parameters:
    ///   - phoneNumber: 手机号（可选）
    ///   - code: 验证码（可选）
    ///   - nowPassword: 当前密码（可选）
    @MainActor
    func deleteAccount(phoneNumber: Int?, code: String?, nowPassword: String?) async throws {
        do {
            _ = try await TDSettingAPI.shared.deleteAccount(phoneNumber: phoneNumber, code: code, nowPassword: nowPassword)
            TDUserManager.shared.logoutCurrentUser()
            TDToastCenter.shared.td_settingShow("settings.account.delete.success".localized, type: .success)
            TDSettingsWindowTracker.shared.closeSettingsWindow()
        } catch {
            TDToastCenter.shared.td_settingShow(error.localizedDescription, type: .error)
            throw error
        }
    }

    
}

// MARK: - Account cards
private extension TDSettingsDetailManager {
    func accountSecurityCards(_ ctx: TDAccountContext) -> [TDSettingsCardModel] {
        [
            TDSettingsCardModel(rows: [
                .info(title: "settings.account.nickname.title".localized, value: ctx.nickname, disclosure: true),
                .gender
            ]),
            TDSettingsCardModel(rows: {
                var rows: [TDSettingsRow] = [
                    .info(title: "settings.account.phone.title".localized, value: ctx.phone, disclosure: true),
                    .info(title: "settings.account.id.title".localized, value: ctx.account, disclosure: true)
                ]
                if ctx.hasAccount {
                    rows.append(.info(title: "settings.account.change_password".localized, value: nil, disclosure: true))
                }
                return rows
            }()),
            TDSettingsCardModel(rows: [
                .binding(title: "settings.account.bind.wechat".localized, bound: ctx.isWechatBound),
                .binding(title: "settings.account.bind.qq".localized, bound: ctx.isQQBound),
                .binding(title: "settings.account.bind.apple".localized, bound: ctx.isAppleIDBound),
                .footer("settings.account.bind.hint".localized)
            ])
        ]
    }
}


// MARK: - 手机号绑定相关
extension TDSettingsDetailManager {
    enum TDBindPhoneFlowError: Error {
        case forceBindNeeded(String)   // 需要强制绑定
        case message(String)           // 普通错误提示
    }
    
    /// 获取绑定/更换手机号验证码
    @MainActor
    func requestBindSmsCode(phone: String) async throws {
        do {
            _ = try await TDSettingAPI.shared.getSmsCodeByBind(phoneNumber: phone)
            
        } catch let err as TDNetworkError {
            // 服务器返回原文（requestFailed 携带），否则用统一错误文案
            if case .requestFailed(let msg) = err {
                throw TDBindPhoneFlowError.message(msg)
            } else {
                throw TDBindPhoneFlowError.message(err.errorMessage)
            }
        } catch {
            throw TDBindPhoneFlowError.message(error.localizedDescription)
        }
    }
    
    /// 绑定/更换手机号
    /// 返回成功则直接结束；code=113/114 转为 forceBindNeeded
    @MainActor
    func bindPhone(phone: String, code: Int) async throws {
        do {
            _ = try await TDSettingAPI.shared.bindPhoneNumber(phoneNumber: phone, code: code)
        } catch let err as TDNetworkError {
            // 113/114：手机号被占用，需要强制绑定确认
            if case .needForceBindPhone = err {
                throw TDBindPhoneFlowError.forceBindNeeded("settings.account.phone.forcebind.message".localized)
            }
            // 服务器原文优先
            if case .requestFailed(let msg) = err {
                throw TDBindPhoneFlowError.message(msg)
            }
            throw TDBindPhoneFlowError.message(err.errorMessage)
        } catch {
            throw TDBindPhoneFlowError.message(error.localizedDescription)
        }
    }
    
    /// 强制绑定手机号
    @MainActor
    func forceBindPhone(phone: String, code: Int) async throws {
        do {
            _ = try await TDSettingAPI.shared.bindPhoneNumberForce(phoneNumber: phone, code: code)
        } catch let err as TDNetworkError {
            if case .requestFailed(let msg) = err {
                throw TDBindPhoneFlowError.message(msg)
            }
            throw TDBindPhoneFlowError.message(err.errorMessage)
        } catch {
            throw TDBindPhoneFlowError.message(error.localizedDescription)
        }
    }

}


// MARK: - 头像上传
extension TDSettingsDetailManager {
    struct TDAvatarUploadResult {
        let image: NSImage?
        let url: String
    }

    /// 处理头像选择并上传到七牛，成功后更新用户信息
    @MainActor
    func uploadAvatar(
        from item: PhotosPickerItem,
        currentUser: TDUserModel?,
        progress: ((Double) -> Void)? = nil
    ) async throws -> TDAvatarUploadResult {
        guard var user = currentUser else { throw QiniuError.uploadFailed("用户信息缺失") }

        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw QiniuError.uploadFailed("读取图片数据失败")
        }
        let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "png"

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("avatar_upload_\(UUID().uuidString).\(ext)")
        try data.write(to: tempURL)

        let attachment = try await TDQiniuManager.shared.uploadAttachment(fileURL: tempURL, progressCallback: progress)

        user.head = attachment.url
        try await updateUserProfile(userManager: user)
        // 覆盖本地缓存，确保侧栏/其他视图立即使用新头像
        if let avatarURL = URL(string: attachment.url) {
            // 先删旧缓存，再下载新头像
            TDAvatarManager.shared.deleteLocalAvatar(for: user.userId)
            try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: user.userId)
        }

        let nsImage = NSImage(data: data)
        return TDAvatarUploadResult(image: nsImage, url: attachment.url)
    }
}

// MARK: - 账号更改/设置账号相关
extension TDSettingsDetailManager {
    
    /// 获取更改账号短信验证码（当前手机号）
    @MainActor
    func requestChangeAccountSmsCode(phoneNumber: Int) async throws {
        do {
            _ = try await TDSettingAPI.shared.sendSmsCodeByChangeAccount(phoneNumber: phoneNumber)
        } catch let err as TDNetworkError {
            if case .requestFailed(let msg) = err {
                throw TDAccountChangeFlowError.smsCode(msg)
            }
            throw TDAccountChangeFlowError.smsCode(err.errorMessage)
        } catch {
            throw TDAccountChangeFlowError.smsCode(error.localizedDescription)
        }
    }
    
    /// 获取老邮箱验证码
    @MainActor
    func requestOldEmailCodeByChangeAccount() async throws {
        do {
            _ = try await TDSettingAPI.shared.sendOldEmailCodeByChangeAccount()
        } catch let err as TDNetworkError {
            if case .requestFailed(let msg) = err {
                throw TDAccountChangeFlowError.oldEmailCode(msg)
            }
            throw TDAccountChangeFlowError.oldEmailCode(err.errorMessage)
        } catch {
            throw TDAccountChangeFlowError.oldEmailCode(error.localizedDescription)
        }
    }
    
    /// 获取新邮箱验证码
    @MainActor
    func requestNewEmailCodeByChangeAccount(newAccount: String) async throws {
        do {
            _ = try await TDSettingAPI.shared.sendNewEmailCodeByChangeAccount(newAccount: newAccount)
        } catch let err as TDNetworkError {
            if case .requestFailed(let msg) = err {
                throw TDAccountChangeFlowError.newEmailCode(msg)
            }
            throw TDAccountChangeFlowError.newEmailCode(err.errorMessage)
        } catch {
            throw TDAccountChangeFlowError.newEmailCode(error.localizedDescription)
        }
    }
    
    /// 确认更改账号（根据是否有手机号/老邮箱，传入对应验证码）
    @MainActor
    func submitChangeAccount(password: String,
                             newAccount: String,
                             newEmailCode: Int,
                             smsCode: Int?,
                             oldEmailCode: Int?) async throws {
        do {
            _ = try await TDSettingAPI.shared.changeAccount(
                password: password,
                newAccount: newAccount,
                newEmailCode: newEmailCode,
                smsCode: smsCode,
                oldEmailCode: oldEmailCode
            )
        } catch let err as TDNetworkError {
            if case .requestFailed(let msg) = err {
                // 简单根据关键字分发到对应输入
                if msg.contains("短信") || msg.contains("手机") {
                    throw TDAccountChangeFlowError.smsCode(msg)
                } else if msg.contains("旧") || msg.contains("老") {
                    throw TDAccountChangeFlowError.oldEmailCode(msg)
                } else if msg.contains("邮") || msg.contains("邮箱") || msg.contains("新") {
                    throw TDAccountChangeFlowError.newEmailCode(msg)
                } else if msg.contains("密") {
                    throw TDAccountChangeFlowError.password(msg)
                } else {
                    throw TDAccountChangeFlowError.general(msg)
                }
            }
            throw TDAccountChangeFlowError.general(err.errorMessage)
        } catch {
            throw TDAccountChangeFlowError.general(error.localizedDescription)
        }
    }
    
    /// 绑定/设置账号密码
    @MainActor
    func submitConfigAccount(setAccount: String, setPassword: String) async throws {
        do {
            _ = try await TDSettingAPI.shared.configAccount(setAccount: setAccount, setPassword: setPassword)
        } catch let err as TDNetworkError {
            if case .requestFailed(let msg) = err {
                throw TDAccountChangeFlowError.general(msg)
            }
            throw TDAccountChangeFlowError.general(err.errorMessage)
        } catch {
            throw TDAccountChangeFlowError.general(error.localizedDescription)
        }
    }
    
    // MARK: - 修改密码占位（按需替换为真实接口）
    @MainActor
    func changePasswordByOld(current: String, newPassword: String) async throws {
        _ = try await TDSettingAPI.shared.changePassword(oldPassword: current, newPassword: newPassword)
        TDToastCenter.shared.td_settingShow("settings.account.nickname.update.success".localized, type: .success)
    }
    
    @MainActor
    func changePasswordByPhone(code: String, newPassword: String) async throws {
        _ = try await TDSettingAPI.shared.changePasswordByPhone(code: code, newPassword: newPassword)
        TDToastCenter.shared.td_settingShow("settings.account.nickname.update.success".localized, type: .success)
    }
    
    @MainActor
    func changePasswordByEmail(code: String, newPassword: String) async throws {
        _ = try await TDSettingAPI.shared.changePasswordByEmail(code: code, newPassword: newPassword)
        TDToastCenter.shared.td_settingShow("settings.account.nickname.update.success".localized, type: .success)
    }

}

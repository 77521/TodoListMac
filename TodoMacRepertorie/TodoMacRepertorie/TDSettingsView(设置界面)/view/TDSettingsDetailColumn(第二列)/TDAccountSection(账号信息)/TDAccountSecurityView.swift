//
//  TDAccountSecurityView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/12.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TDAccountSecurityView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @EnvironmentObject private var userManager: TDUserManager
    
    // 性别选择（1 男，0 女），初始即读取当前用户性别，避免 onAppear 再次赋值触发
    @State private var genderSelection: Int = {
        let sex = TDUserManager.shared.currentUser?.sex ?? -1
        return (sex == 0 || sex == 1) ? sex : 1
    }()

    // 显示昵称编辑弹窗
    @State private var showNameSheet = false
    // 昵称输入草稿
    @State private var nameDraft: String = ""
    // 头像地址
    @State private var headerUrl: String = ""
    // 退出/注销弹窗
    @State private var showLogoutAlert = false
    @State private var showDeleteSheet = false

    // 绑定/更换手机号弹窗
    @State private var showPhoneSheet = false
    @State private var phoneInput: String = ""
    @State private var codeInput: String = ""
    // 头像悬停
    @State private var isAvatarHovering = false
    // 本地选中的头像预览
    @State private var localAvatarImage: Image? = nil
    @State private var avatarPickerItem: PhotosPickerItem? = nil
    @State private var isUploadingAvatar = false
    @State private var avatarUploadProgress: Double = 0
    // 账号/密码修改弹窗
    @State private var showAccountSheet = false
    @State private var accountSheetUser: TDUserModel?

    // 详情数据管理器
    private let detailManager = TDSettingsDetailManager.shared
    // 修改密码选项弹窗
    @State private var showChangePasswordAlert = false
    // 修改密码输入弹窗
    @State private var showChangePasswordSheet = false
    // 修改密码模式
    @State private var changePasswordMode: TDChangePasswordSheet.Mode = .oldPassword

    
    private var user: TDUserModel? { userManager.currentUser }
    
    private var nickname: String {
        userManager.currentUser?.userName ?? "settings.account.nickname.placeholder".localized
    }
    
    private var phone: String {
        guard let phone = user?.phoneNumber, phone > 0 else { return "settings.account.bind_phone".localized }
        return String(phone)
    }
    
    private var account: String {
        let accountValue = userManager.currentUser?.userAccount ?? ""
        return accountValue.isEmpty ? "settings.account.set_account_password".localized : accountValue
    }

    private var hasAccount: Bool {
        let acc = (user?.userAccount ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !acc.isEmpty
    }
    
    private var isWechatBound: Bool {
        let wx = (user?.weChatId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let bindId = (user?.wechatBindOpenid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !wx.isEmpty || !bindId.isEmpty
    }
    
    private var isQQBound: Bool {
        !(user?.qqOpenId ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isAppleIDBound: Bool {
        !(user?.thirdAccId ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                avatarCard
                
                ForEach(cardData) { card in
                    settingsCard(for: card)
                }
                
                // 退出登录按钮（新年红 7→4 渐变）
                Button {
                    // TODO: 实际退出登录逻辑
                    showLogoutAlert = true
                } label: {
                    Text("settings.logout.title".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [
                                    themeManager.fixedColor(themeId: "new_year_red", level: 7),
                                    themeManager.fixedColor(themeId: "new_year_red", level: 4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                
                // 注销登录按钮（警告图标，无背景）
                Button {
                    // TODO: 实际注销逻辑
                    showDeleteSheet = true

                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        Text("settings.account.delete.button".localized)
                            .font(.system(size: 15))
                            .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                }
                .buttonStyle(.plain)
                .padding(.top, 50)

            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            // 上传进度变更不触发整体动画，避免列表闪烁
            .animation(.none, value: avatarUploadProgress)

        }
        .onAppear {
            nameDraft = nickname
            headerUrl = userManager.currentUser?.head ?? ""
            phoneInput = userManager.currentUser?.phoneNumber ?? 0 > 0 ? String(userManager.currentUser?.phoneNumber ?? 0) : ""

        }
        .sheet(isPresented: $showNameSheet) {
            nameEditSheet
                .environmentObject(themeManager)
        }
        .onChange(of: genderSelection) { oldValue, newValue in
            guard oldValue != newValue else { return }
            commitNameChange()
        }
        .onChange(of: avatarPickerItem) { _, newItem in
            guard let item = newItem else { return }
            isUploadingAvatar = true
            avatarUploadProgress = 0
            Task {
                do {
                    let result = try await detailManager.uploadAvatar(
                        from: item,
                        currentUser: userManager.currentUser,
                        progress: { percent in
                            Task { @MainActor in
                                withAnimation(.easeOut(duration: 0.15)) {
                                    avatarUploadProgress = percent
                                }
                            }
                        }
                    )
                    if let nsImage = result.image {
                        localAvatarImage = Image(nsImage: nsImage)
                    }
                    headerUrl = result.url
                } catch {
                    TDToastCenter.shared.td_settingShow(error.localizedDescription, type: .error)
                }
                await MainActor.run { isUploadingAvatar = false }
            }
        }
        // 绑定/更换手机号弹窗
        .sheet(isPresented: $showPhoneSheet) {
            TDBindPhoneSheet(
                phone: $phoneInput,
                code: $codeInput,
                themeManager: themeManager,
                detailManager: detailManager,
                title: userManager.currentUser?.phoneNumber ?? 0 > 0
                ? "settings.account.phone.change.title".localized
                : "settings.account.phone.bind.title".localized,
                onSuccess: {
                    // 绑定成功的后续逻辑（可选）
                    guard let user = userManager.currentUser else {
                        return
                    }
                    TDUserManager.shared.updateUserInfo(user)

                    TDToastCenter.shared.td_settingShow("settings.account.phone.bind.success".localized, type: .success)
                }
            )
        }
        .alert("settings.logout.title".localized, isPresented: $showLogoutAlert) {
            Button("common.cancel".localized, role: .cancel) {
                showLogoutAlert = false
            }
            Button("common.confirm".localized, role: .destructive) {
                Task { await detailManager.logout() }
            }
        } message: {
            Text("settings.logout.message".localized)
        }
        // 账号/密码修改弹窗放在根级，避免作用域问题导致空白
        .sheet(isPresented: $showAccountSheet) {
            if let sheetUser = accountSheetUser ?? userManager.currentUser {
                TDAccountChangeSheet(user: sheetUser)
                    .environmentObject(themeManager)
            }
        }
        // 注销账号弹窗
        .sheet(isPresented: $showDeleteSheet) {
            if let u = userManager.currentUser {
                TDDeleteAccountSheet(user: u) {
                    // 退出后关闭设置窗口
                    Task { await detailManager.logout() }
                }
                .environmentObject(themeManager)
            }
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            if let u = userManager.currentUser {
                TDChangePasswordSheet(
                    mode: changePasswordMode,
                    maskedPhone: String.maskedPhoneNumber(from: u.phoneNumber),
                    emailAccount: u.userAccount.isValidEmailFormat() ? u.userAccount : nil
                )
                .environmentObject(themeManager)
            }
        }
        .alert("settings.account.change_password.alert.title".localized, isPresented: $showChangePasswordAlert) {
            // 旧密码
            Button("settings.account.change_password.method.old".localized) {
                changePasswordMode = .oldPassword
                showChangePasswordSheet = true
            }
            // 邮箱（当账号是邮箱时）
            if let acc = user?.userAccount, acc.isValidEmailFormat() {
                Button("settings.account.change_password.method.email".localizedFormat(acc)) {
                    changePasswordMode = .email
                    showChangePasswordSheet = true
                }
            }
            // 手机
            if let phoneNum = user?.phoneNumber, phoneNum > 0, let masked = String.maskedPhoneNumber(from: phoneNum) {
                Button("settings.account.change_password.method.phone".localizedFormat(masked)) {
                    changePasswordMode = .phone
                    showChangePasswordSheet = true
                }
            }
            // 取消
            Button("common.cancel".localized, role: .cancel) {
                showChangePasswordAlert = false
            }
        } message: {
            Text("settings.account.change_password.alert.message".localized)
        }


    }
    
    private var avatarCard: some View {
        cardContainer(withBackground: false) {
            VStack(spacing: 12) {
                ZStack(alignment: .bottom) {
                    avatarView
                        .frame(width: 88, height: 88)
                        .overlay(alignment: .center) {
                            if isUploadingAvatar {
                                let progress = min(max(avatarUploadProgress, 0), 1)
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                    // 背景白圈
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 52, height: 52)
                                    // 进度圈，主题 6 级颜色
                                    Circle()
                                        .trim(from: 0, to: progress)
                                        .stroke(
                                            themeManager.color(level: 6),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 52, height: 52)
                                    VStack(spacing: 2) {
                                        Text("\(Int(progress * 100))%")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }

                    PhotosPicker(selection: $avatarPickerItem, matching: .images, photoLibrary: .shared()) {
                        ZStack(alignment: .bottom) {
                            // 底部弧形遮罩，贴合圆形头像下缘
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .mask(
                                    VStack(spacing: 0) {
                                        Spacer()
                                        Rectangle().frame(height: 30)
                                    }
                                )
                            
                            Text("common.edit".localized)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(width: 88) // 与头像同宽，铺满底部
                    .frame(height: 88)
                    .offset(y: -1)    // 微上移，使弧形覆盖头像下缘
                    .opacity(isAvatarHovering ? 1 : 0)
                    .allowsHitTesting(isAvatarHovering)
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .padding(.bottom, 0)
                }
                // 扩大悬停区域为整个方形容器
                .frame(width: 110, height: 110)
                .contentShape(Rectangle())
                // 悬停区域覆盖整个头像区域
                .onHover { hovering in
                    isAvatarHovering = hovering
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let localAvatarImage {
            localAvatarImage
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else if let url = userManager.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Circle()
                        .strokeBorder(themeManager.descriptionTextColor.opacity(0.35), lineWidth: 1)
                        .overlay(Image(systemName: "person.fill").foregroundColor(themeManager.titleTextColor))
                }
            }
            .clipShape(Circle())
        } else {
            Circle()
                .strokeBorder(themeManager.descriptionTextColor.opacity(0.35), lineWidth: 1)
                .overlay(Image(systemName: "person.fill").foregroundColor(themeManager.titleTextColor))
        }
    }
    
    private func infoRow(title: String, value: String?, showsDisclosure: Bool = true) -> some View {
        HStack {
            Text(title)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            if let value {
                Text(value)
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private var genderRow: some View {
        HStack {
            Text("settings.account.gender.title".localized)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
//            if !(user?.sex == 0 || user?.sex == 1) {
//                Text("settings.account.gender.set".localized)
//                    .foregroundColor(themeManager.descriptionTextColor)
//            }
            Picker("", selection: $genderSelection) {
                Text("settings.account.gender.male".localized).tag(1)
                Text("settings.account.gender.female".localized).tag(0)
            }
            .labelsHidden()
            .pickerStyle(.menu)

        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private func bindingRow(title: String, bound: Bool) -> some View {
        let subtitle: String? = {
            guard !bound else { return nil }
            if title == "settings.account.bind.wechat".localized {
                return "settings.account.bind.wechat.desc".localized
            } else if title == "settings.account.bind.qq".localized {
                return "settings.account.bind.qq.desc".localized
            } else if title == "settings.account.bind.apple".localized {
                return "settings.account.bind.apple.desc".localized
            }
            return nil
        }()
        
        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .foregroundColor(themeManager.titleTextColor)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Text(bound ? "settings.account.bound".localized : "settings.account.unbound".localized)
                .foregroundColor(bound ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    

    // MARK: - Card data + helpers
    private var cardData: [TDSettingsCardModel] {
        detailManager.accountSecurityCards(
            nickname: nickname,
            phone: phone,
            account: account,
            hasAccount: hasAccount,
            isWechatBound: isWechatBound,
            isQQBound: isQQBound,
            isAppleIDBound: isAppleIDBound
        )
    }
    
    @ViewBuilder
    private func settingsCard(for card: TDSettingsCardModel) -> some View {
        cardContainer {
            ForEach(Array(card.rows.enumerated()), id: \.offset) { idx, row in
                switch row {
                case let .info(title, value, disclosure):
                    let rowView = infoRow(title: title, value: value, showsDisclosure: disclosure)
                    if title == "settings.account.nickname.title".localized {
                        rowView
                            .onTapGesture {
                                nameDraft = nickname
                                showNameSheet = true
                            }
                    } else if title == "settings.account.phone.title".localized {
                        rowView
                            .onTapGesture {
                                showPhoneSheet = true
                            }
                    } else if title == "settings.account.id.title".localized {
                        rowView
                            .onTapGesture {
                                guard let u = userManager.currentUser else { return }
                                accountSheetUser = u
                                showAccountSheet = true
                            }
                    } else if title == "settings.account.change_password".localized {
                        rowView
                            .onTapGesture {
                                showChangePasswordAlert = true
                            }
                    } else {
                        rowView
                    }
                case .gender:
                    genderRow
                case let .binding(title, bound):
                    bindingRow(title: title, bound: bound)
                case .footer:
                    EmptyView()
                }

                if idx < card.rows.count - 1 {
                    themedDivider
                }
            }
        }
    }
    
    private var themedDivider: some View {
        Rectangle()
            .fill(themeManager.separatorColor)
            .frame(height: 1)
            .padding(.leading, 0)
    }
    
    private func cardContainer<Content: View>(withBackground: Bool = true,
                                              @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if withBackground {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeManager.backgroundColor)
                } else {
                    Color.clear
                }
            }
        )
    }
    
    private var nameEditSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.account.nickname.edit.title".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            TextField("settings.account.nickname.edit.placeholder".localized, text: $nameDraft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { commitNameChange() }
            
            HStack {
                Spacer()
                Button("common.cancel".localized) {
                    showNameSheet = false
                }
                Button("common.update".localized) {
                    commitNameChange()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func commitNameChange() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showNameSheet = false
            return
        }
        guard var user = userManager.currentUser else {
            showNameSheet = false
            return
        }
        user.userName = trimmed
        user.sex = genderSelection
        Task {
            do {
                try await detailManager.updateUserProfile(userManager: user)
            } catch {
                // 简单忽略错误并关闭弹窗；可根据需求添加错误提示
            }
            await MainActor.run {
                showNameSheet = false
            }
        }
    }


}

#Preview {
    TDAccountSecurityView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDSettingsSidebarStore.shared)
        .environmentObject(TDUserManager.shared)
}

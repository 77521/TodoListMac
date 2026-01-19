//
//  TDUserModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI
//import HandyJSON

struct TDUserModel: Codable {
    let accountChangeNum: Int
    let alphaTest: Int
    let appName: String
    let blackReason: String?
    let blacklist: Bool
    let createTime: Int64
    let desktopTrialTime: Int64
    let deviceId: String?  // 改为可选类型
    let deviceType: String?
    let emailCode: Int
    let emailCode2: Int
    let emailCode2Account: String
    let emailCodeErrorNum: Int
    let fromTaskTable: Int
    var head: String
    let loginDeviceNum: Int
    let loginIp: String
    let packageName: String
    var phoneNumber: Int
    let qqOpenId: String
    var sex: Int
    let smsCode: Int
    let smsCodeErrorNum: Int
    let smsCodePhoneNumber: Int
    let smsType: Int  // 改为Int
    let snow: Int
    let syncLock: Bool  // 改为Bool
    let syncLockTime: Int64
    let taskCompleted: Int
    let tdChannelCode: String
    let third2AccId: String?
    let third3AccId: String?
    let thirdAccId: String?
    let token: String
    let tomatoGain: Int
    let totalRechargeMouth: Int
    let totalRechargeNum: Int
    let umChannelCode: String?
    let unionId: String  // 改为String
    let usedSnow: Int
    var userAccount: String
    let userId: Int
    var userName: String
    let userPassword: String?
    var vip: Bool  // 改为Bool
    let vipDeadTime: Int64
    let weChatId: String
    let wechatAddOpen: Bool  // 改为Bool
    // 后端可能返回 null，改为可选避免解码失败
    let wechatBindOpenid: String?
    let wechatReminderOpen: Bool  // 改为Bool
    let wechatReminderPrivacy: Bool  // 改为Bool
    let welcomeTF: Int
    
    // 用于判断用户是否是VIP
    var isVIP: Bool {
        let currentTimeMillis = Int64(Date().timeIntervalSince1970 * 1000)
        // 直接使用vip字段，因为它现在是Bool类型
        return vip && vipDeadTime > currentTimeMillis
    }

}

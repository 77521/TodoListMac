//
//  TDQrCodeModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation

// MARK: - 获取二维码接口返回模型

/// 二维码完整数据模型
/// 用于 getTodoQrCode（获取二维码）和 getQrVerifyResult（查询验证结果）两个接口
struct TDQrCodeModel: Codable {
    /// 二维码记录唯一ID
    let id: Int
    /// 二维码生成时间（毫秒时间戳）
    let createTime: Int64?
    /// 生成二维码的设备信息（桌面端传 mac）
    let createDeviceType: String?
    /// 请求二维码端的IP地址
    let requestUserIp: String?
    /// 二维码类型：1=鸿蒙手表，2=AndroidWear手表，3=桌面端
    let codeType: Int?
    /// 二维码代码串，用于生成二维码图片和后续轮询查询
    let qrCode: String?

    /// 扫码用户ID（扫描后才有值）
    let scanUserId: Int?
    /// 扫码用户的 token（扫描后才有值）
    let scanUserToken: String?
    /// 扫描用户的IP地址（扫描后才有值）
    let scanUserIp: String?
    /// 扫码时间（毫秒时间戳，扫描后才有值）
    let scanTime: Int64?
    /// 扫码设备信息（扫描后才有值）
    let scanDeviceType: String?
    /// 验证扫码结果：0=待验证，1=成功，-1=失败
    let qrVerify: Int?
    /// 登录成功后返回给设备的用户对象（验证通过后才有值）
    let okUser: TDUserModel?
}

// MARK: - 二维码验证状态枚举

/// 二维码验证状态
enum TDQrVerifyStatus: Int {
    /// 待验证（等待手机扫码）
    case waiting = 0
    /// 验证成功（手机已确认登录）
    case success = 1
    /// 验证失败（手机拒绝或其他原因）
    case failed = -1
}

// MARK: - 二维码展示状态枚举

/// 扫码登录视图的展示状态机
enum TDQrCodeViewStatus: Equatable {
    /// 正在请求获取二维码（初始加载）
    case loading
    /// 二维码已就绪，等待手机扫码
    case ready
    /// 手机已扫码，等待用户在手机上确认
    case scanned
    /// 登录成功
    case success
    /// 二维码已过期或验证失败，需要刷新
    case expired
    /// 网络/接口错误，携带错误描述
    case error(String)

    /// 展示给用户的状态提示文案 key（国际化）
    var statusTextKey: String {
        switch self {
        case .loading:  return "login.qrcode.status.loading"
        case .ready:    return "login.qrcode.status.ready"
        case .scanned:  return "login.qrcode.status.scanned"
        case .success:  return "login.qrcode.status.success"
        case .expired:  return "login.qrcode.status.expired"
        case .error:    return "login.qrcode.status.error"
        }
    }
}

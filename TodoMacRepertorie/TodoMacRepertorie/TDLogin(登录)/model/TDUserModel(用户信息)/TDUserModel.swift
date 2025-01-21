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
    let deviceType: String
    let emailCode: Int
    let emailCode2: Int
    let emailCode2Account: String
    let emailCodeErrorNum: Int
    let fromTaskTable: Int
    let head: String
    let loginDeviceNum: Int
    let loginIp: String
    let packageName: String
    let phoneNumber: Int
    let qqOpenId: String
    let sex: Int
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
    let userAccount: String
    let userId: Int
    let userName: String
    let userPassword: String?
    let vip: Bool  // 改为Bool
    let vipDeadTime: Int64
    let weChatId: String
    let wechatAddOpen: Bool  // 改为Bool
    let wechatBindOpenid: String
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
//struct TDUserModel : HandyJSON{
//    
//    //单列
//     var id: String = UUID().uuidString
//    /*用户id*/
//     var userId : Int? = -1
//    /*设备唯一标识*/
//     var deviceId : String? = ""
//    /*设备型号*/
//     var deviceType : String? = ""
//    /*账号注册时间*/
//     var createTime : Int? = 0
//    /*账号名*/
//     var userAccount : String? = ""
//    /*密码*/
//     var userPassword : String? = ""
//    /*手机号*/
//     var phoneNumber : Int? = 0
//    /*用户token*/
//     var token : String? = ""
//    /*昵称名*/
//     var userName : String? = ""
//    /*头像*/
//     var head : String? = ""
//    /*性别 1男 0女 */
//     var sex : Int? = -1
//    /*是否是会员*/
//     var vip : Bool? = false
//    /*会员到期时间*/
//     var vipDeadTime : Int? = 0
//    /*是否被拉黑*/
//     var isBlacklist : Bool? = false
//    /*是否更改过账号*/
//     var accountChangeNum : Int? = 0
//    /*拉黑原因*/
//     var blackReason : String? = ""
//    /*当前拥有雪花总量*/
//     var snow : Int? = 0
//    /*已使用的雪花总量*/
//     var userdSnow : Int? = 0
//
//    /*qqid*/
//     var qqOpenId : Bool? = false
//    /*微信id*/
//     var weChatId : Bool? = false
//    /*苹果绑定*/
//     var thirdAccId : Bool? = false
//    /*登录设备数*/
//     var loginDeviceNum : Int? = 0
//    /*TF更新时间*/
//     var welcomeTF : Int? = 0
//
//    /*设置界面 微信公众号字段*/
//    /*在微信公众号提醒开启流程中，和原weChatId字段结合来判断是否已绑定微信*/
//     var unionId : Bool? = false
//    /*微信公众号id*/
//     var wechatBindOpenid : Bool? = false
//    /*微信公众号快捷添加开关*/
//     var wechatAddOpen : Bool? = false
//    /*微信公众号提醒开关*/
//     var wechatReminderOpen : Bool? = false
//    /*微信消息提醒的隐私设置，默认关闭。开启后事件内容会隐藏*/
//     var wechatReminderPrivacy : Bool? = false
//    
//     init() {
//        
//    }
//}

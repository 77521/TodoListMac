//
//  UserInfoDataModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/8.
//

import Foundation
struct UserInfoDataModel {
    static var id: String = UUID().uuidString
    /*用户id*/
    static var userId : Int = -1
    /*设备唯一标识*/
    static var deviceId : String = ""
    /*设备型号*/
    static var deviceType : String = ""
    /*账号注册时间*/
    static var createTime : Int = 0
    /*账号名*/
    static var userAccount : String = ""
    /*密码*/
    static var userPassword : String = ""
    /*手机号*/
    static var phoneNumber : Int = 0
    /*用户token*/
    static var token : String = ""
    /*昵称名*/
    static var userName : String = ""
    /*头像*/
    static var head : String = ""
    /*性别 1男 0女 */
    static var sex : Int = -1
    /*是否是会员*/
    static var vip : Bool = false
    /*会员到期时间*/
    static var vipDeadTime : Int = 0
    /*是否被拉黑*/
    static var isBlacklist : Bool = false
    /*是否更改过账号*/
    static var accountChangeNum : Int = 0
    /*拉黑原因*/
    static var blackReason : String = ""
    /*当前拥有雪花总量*/
    static var snow : Int = 0
    /*已使用的雪花总量*/
    static var userdSnow : Int = 0

    /*qqid*/
    static var qqOpenId : Bool = false
    /*微信id*/
    static var weChatId : Bool = false
    /*苹果绑定*/
    static var thirdAccId : Bool = false
    /*登录设备数*/
    static var loginDeviceNum : Int = 0
    /*TF更新时间*/
    static var welcomeTF : Int = 0

    /*设置界面 微信公众号字段*/
    /*在微信公众号提醒开启流程中，和原weChatId字段结合来判断是否已绑定微信*/
    static var unionId : Bool = false
    /*微信公众号id*/
    static var wechatBindOpenid : Bool = false
    /*微信公众号快捷添加开关*/
    static var wechatAddOpen : Bool = false
    /*微信公众号提醒开关*/
    static var wechatReminderOpen : Bool = false
    /*微信消息提醒的隐私设置，默认关闭。开启后事件内容会隐藏*/
    static var wechatReminderPrivacy : Bool = false
    
    static var isLogin : Bool {
        token.isEmpty ? false : true
    }

}

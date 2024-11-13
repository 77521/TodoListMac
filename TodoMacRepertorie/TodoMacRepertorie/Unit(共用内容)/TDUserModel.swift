//
//  TDUserModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import Foundation
import SwiftUI
import HandyJSON

struct TDUserModel : HandyJSON{
    
    //单列
     var id: String = UUID().uuidString
    /*用户id*/
     var userId : Int = -1
    /*设备唯一标识*/
     var deviceId : String = ""
    /*设备型号*/
     var deviceType : String = ""
    /*账号注册时间*/
     var createTime : Int = 0
    /*账号名*/
     var userAccount : String = ""
    /*密码*/
     var userPassword : String = ""
    /*手机号*/
     var phoneNumber : Int = 0
    /*用户token*/
     var token : String = ""
    /*昵称名*/
     var userName : String = ""
    /*头像*/
     var head : String = ""
    /*性别 1男 0女 */
     var sex : Int = -1
    /*是否是会员*/
     var vip : Bool = false
    /*会员到期时间*/
     var vipDeadTime : Int = 0
    /*是否被拉黑*/
     var isBlacklist : Bool = false
    /*是否更改过账号*/
     var accountChangeNum : Int = 0
    /*拉黑原因*/
     var blackReason : String = ""
    /*当前拥有雪花总量*/
     var snow : Int = 0
    /*已使用的雪花总量*/
     var userdSnow : Int = 0

    /*qqid*/
     var qqOpenId : Bool = false
    /*微信id*/
     var weChatId : Bool = false
    /*苹果绑定*/
     var thirdAccId : Bool = false
    /*登录设备数*/
     var loginDeviceNum : Int = 0
    /*TF更新时间*/
     var welcomeTF : Int = 0

    /*设置界面 微信公众号字段*/
    /*在微信公众号提醒开启流程中，和原weChatId字段结合来判断是否已绑定微信*/
     var unionId : Bool = false
    /*微信公众号id*/
     var wechatBindOpenid : Bool = false
    /*微信公众号快捷添加开关*/
     var wechatAddOpen : Bool = false
    /*微信公众号提醒开关*/
     var wechatReminderOpen : Bool = false
    /*微信消息提醒的隐私设置，默认关闭。开启后事件内容会隐藏*/
     var wechatReminderPrivacy : Bool = false
    
     init() {
        
    }
}

//
//  TDLeftDataModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/10/11.
//

import Foundation
import SwiftUI

class TDLeftDataModel : TDBaseModel {
    
    /*
     要存入数据库的字段
     */
    /*id 判断点击跳转的标识 -100：DayTodo ,-101：最近待办，-102：日程概览，-103：待办箱，-104：分类清单，-105：标签，-106：数据统计，-107：最近已完成，-108：回收站*/
    var categoryId : Int? = -100
    /*标题*/
    var categoryName : String? = "未分类"
    /*颜色 网络数据使用*/
    var categoryColor : String? = ""
    /*创建时间*/
    var createTime : Int64? = 0
    /*排序，从小到大，从100开始，每次增加100*/
    var listSort : Double? = 0.0
    /// 最大更改值
    var anchor : Int? = 0
    /// 用户ID
    var userId : Int? = 0
    
    // 图片
    var headerIcon : String? = ""
    
    // DayTodo 今天未完成的数量
    var dayTodoNoFinishNumber : Int? = 1
        
    // 分类清单数组
    var categoryDatas : [TDLeftDataModel] = [TDLeftDataModel]()
    
    // 是否选中
    var isSelect : Bool = false
    
    // 鼠标剪头是否在当前组头
    var isHovering : Bool = false
    
    // 背景颜色
    var backgroundColor : Color? {
        if isHovering && categoryId! < 0 {
            if isSelect {
                return .blue
            }
            return .greyColor1
        }
        if isSelect && categoryId! < 0 {
            return .blue
        }
        return .clear
    }
    
    // 字体颜色
    var titleColor : Color? {
        if isSelect && categoryId! < 0 {
            return .white
        }
        return .greyColor6
    }
    
    // 图标颜色
    var iconColor : Color? {
        if isSelect && categoryId! < 0 {
            return .white
        }
        return Color.themeColor(i: 5)
    }
    
    
}


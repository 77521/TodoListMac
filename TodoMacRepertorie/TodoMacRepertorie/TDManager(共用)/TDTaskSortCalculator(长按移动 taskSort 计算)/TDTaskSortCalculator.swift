//
//  TDTaskSortCalculator.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/2/7.
//

import Foundation

/// TaskSort 计算工具（与 iOS 端逻辑保持一致）
///
/// 说明：
/// - iOS 端的原始实现使用 `double`，这里使用 `Decimal` 存储（项目模型字段为 `Decimal`）。
/// - `topTaskSort / nextTaskSort` 取值约定：
///   - **nil**：表示不存在，或该相邻数据是“系统订阅事件”（不可参与 taskSort 计算）
/// - 随机数范围与默认值来自 `TDAppConfig`：`minTaskSort / maxTaskSort / defaultTaskSort`
struct TDTaskSortCalculator {
    /// 计算“移动事件”时的新 taskSort 值（iOS 同款逻辑）
    ///
    /// - Parameters:
    ///   - currentTaskSort: 当前移动的事件自身 taskSort
    ///   - topTaskSort: 目标位置的上一个 taskSort；如果不存在/或系统订阅事件：传 nil
    ///   - nextTaskSort: 目标位置的下一个 taskSort；如果不存在/或系统订阅事件：传 nil
    /// - Returns: 新的 taskSort
    static func getMoveCurrentTaskSortValue(
        currentTaskSort: Decimal,
        topTaskSort: Decimal?,
        nextTaskSort: Decimal?
    ) -> Decimal {
        // iOS：top == -1 && next >= 0
        if topTaskSort == nil, let nextTaskSort {
            // 如果 nextTaskSort > TD_TASKSORT_MAX * 2，则减去随机数；否则除以 2
            if nextTaskSort > TDAppConfig.maxTaskSort * 2 {
                return nextTaskSort - TDAppConfig.randomTaskSort()
            } else {
                return nextTaskSort / 2
            }
        }

        // iOS：top >= 0 && next == -1
        if let topTaskSort, nextTaskSort == nil {
            // 新顺序值只考虑 top：top + 随机数
            return topTaskSort + TDAppConfig.randomTaskSort()
        }

        // iOS：top >= 0 && next >= 0
        if let topTaskSort, let nextTaskSort {
            return (topTaskSort + nextTaskSort) / 2
        }

        // 兜底：不计算，返回原值
        return currentTaskSort
    }
}


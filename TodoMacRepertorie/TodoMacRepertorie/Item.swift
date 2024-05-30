//
//  Item.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/5/30.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

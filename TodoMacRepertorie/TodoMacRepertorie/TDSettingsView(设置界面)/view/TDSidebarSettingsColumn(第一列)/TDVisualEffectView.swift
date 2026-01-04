//
//  TDVisualEffectView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/31.
//

import SwiftUI

/// SwiftUI wrapper for NSVisualEffectView to achieve real macOS blur that samples the desktop.
struct TDVisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var emphasized: Bool = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        v.isEmphasized = emphasized
        v.autoresizingMask = [.width, .height]
        v.translatesAutoresizingMaskIntoConstraints = true
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
        nsView.isEmphasized = emphasized
    }
}

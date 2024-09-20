//
//  TDBridTextField.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/23.
//

import SwiftUI

struct TDBridTextField: View {
    @Binding var text: String
    var titleKey: String
    var isAccount : Bool

    @State var isSecure: Bool = true
    
    @State private var isFirst = true
    @State var isCountingDown : Bool = false
    @State var remainingSeconds : Int = 60
    @State var timer : Timer?
    var body: some View {
        HStack(alignment:.center){
            Group{
                if isSecure{
                    SecureField(titleKey, text: $text)
                    
                }else{
                    TextField(titleKey, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSecure)
            
            if isAccount {
                Button(action: {
                    isSecure.toggle()
                }, label: {
                    Image(systemName: !isSecure ? "eye.slash.fill" : "eye.fill" )
                        .foregroundStyle(Color.greyColor4)
                })
                .frame(width: 20, height: 20)
                .buttonStyle(.plain)
                
                Button(action: {
                    
                }, label: {
                    Image(systemName: "questionmark.circle.fill" )
                        .foregroundStyle(Color.greyColor2)
                        .frame(width: 15, height: 15)
                })
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    startCountdown()
                }, label: {
                    Text(isFirst ? "验证码" : isCountingDown ? "\(remainingSeconds)s" : "重新发送")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .frame(height: 30)
                        .padding(.horizontal,10)
                        .background(Color.marrsGreenColor6)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                })
                .buttonStyle(.plain)
                .allowsHitTesting(isFirst ? true : !isCountingDown)
            }
            
        }//Add any modifiers shared by the Button and the Fields here
    }
    
    func startCountdown() {
        isFirst = false
        isCountingDown = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 1 {
                remainingSeconds -= 1
            } else {
                stopCountdown()
            }
        }
    }
    
    func stopCountdown() {
        isCountingDown = false
        remainingSeconds = 60
        timer?.invalidate()
        timer = nil
    }

}

#Preview {
    TDBridTextField(text: .constant("邮箱登录"), titleKey: "手机号登录", isAccount: false)
}

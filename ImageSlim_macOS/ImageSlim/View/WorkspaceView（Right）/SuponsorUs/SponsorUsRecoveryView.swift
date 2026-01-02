//
//  SponsorUsRecoveryView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/1.
//

import SwiftUI

struct SponsorUsRecoveryView: View {
    @EnvironmentObject var appStorage: AppStorage
    @EnvironmentObject var sound: SoundManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        let recoveryText = appStorage.inAppPurchaseMembership ? "Recovery successful" : "No recovery records found"
        let lottieName = appStorage.inAppPurchaseMembership ? "check" : "NoEntry"
        let soundName = appStorage.inAppPurchaseMembership ? "success" : "errorSound"
        
        VStack {
            LottieMacView(filename: lottieName, isPlaying: true, playCount: 1, isReversed: false)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Button(action:{
                dismiss()
            }, label: {
                Text(LocalizedStringKey(recoveryText))
                    .BlueButtonText()
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
        }
        .padding(.horizontal,14)
        .frame(width: 200,height: 200)
        .onAppear {
            sound.playSound(named: soundName)   // 播放音效
        }
    }
}

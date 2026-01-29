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
        let recoveryText = appStorage.inAppPurchaseMembership ? "Restored Successfully" : "No records to restore"
        let lottieName = appStorage.inAppPurchaseMembership ? "check" : "NoEntry"
        let soundName = appStorage.inAppPurchaseMembership ? "success" : "errorSound"
        
        VStack(spacing: 10) {
            LottieMacView(filename: lottieName, isPlaying: true, playCount: 1, isReversed: false)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            
            Text(LocalizedStringKey(recoveryText))
                .fontWeight(.bold)
            
            Button(action:{
                dismiss()
            }, label: {
                Text("Done")
                    .BlueButtonText()
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
        }
        .padding(.horizontal,14)
        .frame(width: 250,height: 230)
        .onAppear {
            sound.playSound(named: soundName)   // 播放音效
        }
    }
}

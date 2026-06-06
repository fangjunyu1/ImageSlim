//
//  SponsorUsSuccessView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/1.
//

import SwiftUI

struct SponsorUsResultsView: View {
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var sound: SoundManager
    
    var body: some View {
        let lottieName = "check1"
        VStack(spacing: 16) {
            LottieMacView(filename: lottieName, isPlaying: true, playCount: 2, isReversed: false)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Text("All features unlocked. Thanks for your support!")
                .foregroundColor(.gray)
            Button(action: {
                iapManager.successTips = false
            }, label: {
                Text("Done")
                    .BlueButtonText()
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
        }
        .padding(.horizontal,14)
        .frame(width: 300,height: 250)
        .overlay {
            LottieMacView(filename: "Fireworks1", isPlaying: true, playCount: 0, isReversed: false)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 250)
                .disabled(true)
        }
        .onAppear {
            sound.playSound(named: "success")   // 播放音效
        }
    }
}

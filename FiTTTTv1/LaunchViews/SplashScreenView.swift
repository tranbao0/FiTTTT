//
//  SplashScreenView.swift
//  Fitness App
//
//  Created by Juan Tehuintle Temor on 4/30/25.
//
import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Fullscreen black background
            Color.black
                .ignoresSafeArea()

            // Centered content: logo and loading dots
            VStack(alignment: .center, spacing: 15.16084) {
                // Replace with Image("LogoAssetName") if you have a vector/logo asset
                Image("FiTTTTLogo")
                    .renderingMode(.template)         // if your PDF is a single‐color icon
                    .resizable()                      // enable scaling
                    .aspectRatio(contentMode: .fit)   // preserve its proportions
                    .frame(width: 120, height: 40)    // tweak to match your Figma size
                    .foregroundColor(.white)          // tints a template PDF white

                // Loading indicator dots
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                    
                }
            }
            .padding(.horizontal, 98)
            .padding(.top, 362)
            .padding(.bottom, 420.10144)
            .frame(width: 393, height: 852, alignment: .top)
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}

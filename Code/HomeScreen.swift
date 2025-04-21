//
//  HomeScreen.swift
//  Fitness App
//

import SwiftUI

struct HomeScreen: View {
    var body: some View {
        VStack {
            Text("Welcome to the FiTTTT")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "figure.walk")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
        }
        .padding()
        .navigationTitle("Home") // Moved navigationTitle outside VStack
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}

import SwiftUI
import Foundation

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            ZStack {
                // Background color matching storyboard RGB values
                Color(red: 0.4509, green: 0.9883, blue: 0.8376)
                    .opacity(0.65)
                    .ignoresSafeArea()

                // Centered logo image
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 418, height: 458)
            }
        }
    }
}

import Foundation
import SwiftUI

struct PatchNoteView: View {
    var groupedPatchNotes: [PatchNoteSection]
    
    var onDismiss: (() -> Void)?
    
    var body: some View {            
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(TranslationUnit.getMessage(for: .PATCH_NOTES) ?? "Patch Notes")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.black)
            }
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(groupedPatchNotes) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.date)
                                .font(.headline)
                                .foregroundColor(.black)
                            ForEach(section.messages, id: \.self) { msg in
                                Text("• \(msg)")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
                .padding([.top, .bottom], 12) // vertical spacing only
                .padding(.horizontal, 16)
            }
            // TODO: maybe add blurred background
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.horizontal)
            
            VStack {
                HStack(spacing: 20) {
                    Text(TranslationUnit.getMessage(for: .CLOSE_PATCH_NOTES) ?? "Thank you!")
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.horizontal)
            .onTapGesture {
                print("Closing PatchNoteView")
                onDismiss?()
            }
        }
        .padding()
        .background(Color(red: 210 / 255, green: 248 / 255, blue: 210 / 255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding()
        .transition(.opacity)
        .zIndex(6)
    }
}

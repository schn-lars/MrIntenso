import Foundation
import SwiftUI

// https://stackoverflow.com/questions/61335519/swiftui-how-can-i-catch-changing-value-from-observed-object-when-i-execute-func

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var mainViewModel: AppViewModel
    
    @State private var showResetCacheAlert: Bool = false
    @State private var showResetAllAlert: Bool = false
    @State private var showResetBasketAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(UserDefaultsKeys.allCases, id: \.self) { key in
                    switch key {
                    case .AUTO_DOWNLOAD:
                        AnyView(
                            HStack {
                                if let msg = TranslationUnit.getMessage(for: .AUTO_DOWNLOAD) {
                                    Text(msg)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Toggle("", isOn: $settings.autoDownload)
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                }
                            }
                        )
                    case .SEGMENTATION_THRESHOLD:
                        AnyView(
                            HStack {
                                if let msg = TranslationUnit.getMessage(for: .SEGMENTATION_THRESHOLD) {
                                    Text(msg)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Text("\(settings.segmentation, specifier: "%.1f")")
                                        .font(.system(size: 16))
                                    Slider(value: $settings.segmentation, in: 0.0...1.0)
                                        .frame(width: 100)
                                }
                            }
                        )
                    case .IOU_THRESHOLD:
                        AnyView(
                            HStack {
                                if let msg = TranslationUnit.getMessage(for: .IOU_THRESHOLD) {
                                    Text(msg)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Text("\(settings.iou, specifier: "%.1f")")
                                        .font(.system(size: 16))
                                    Slider(value: $settings.iou, in: 0.0...1.0)
                                        .frame(width: 100)
                                }
                            }
                        )
                    case .LANGUAGE:
                        AnyView(
                            HStack {
                                if let msg = TranslationUnit.getMessage(for: .LANGUAGE) {
                                    Text(msg)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Picker(key.rawValue, selection: $settings.language) {
                                        ForEach(Constants.getLanguages(), id: \.self) { language in
                                            Text(language).tag(language)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .labelsHidden()
                                }
                            }
                        )
                    case .JOKE:
                        AnyView(
                            HStack {
                                if let msg = TranslationUnit.getMessage(for: .JOKE) {
                                    Text(msg)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Picker(key.rawValue, selection: $settings.joke) {
                                        ForEach(Constants.getJokeSettings(), id: \.self) { joke in
                                            Text(joke).tag(joke)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .labelsHidden()
                                }
                            }
                        )
                    case .REVERSE_SEARCH:
                        AnyView(
                            HStack {
                                if let msg = TranslationUnit.getMessage(for: .REVERSE_SEARCH) {
                                    Text(msg)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Toggle("", isOn: $settings.useReverseSearch)
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                }
                            }
                        )
                    }
                }
            }
            .scrollDisabled(true)
            
            Spacer()
            
            List {
                if let msg = TranslationUnit.getMessage(for: .RESET_CACHE),
                   let description = TranslationUnit.getMessage(for: .RESET_CACHE_DESCRIPTION),
                   let dismiss = TranslationUnit.getMessage(for: .OPTION_DISMISS),
                   let reset = TranslationUnit.getMessage(for: .OPTION_RESET){
                    HStack {
                        Button(role: .destructive) {
                            showResetCacheAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text(msg)
                                    .font(.system(size: 16))
                                Spacer()
                            }
                        }
                        .alert(isPresented: $showResetCacheAlert) {
                            Alert(
                                title: Text(msg),
                                message: Text(description),
                                primaryButton: .cancel(Text(dismiss)),
                                secondaryButton: .destructive(Text(reset), action: mainViewModel.resetCache)
                            )
                        }
                    }
                }
                
                
                if let msg = TranslationUnit.getMessage(for: .RESET_BASKET),
                   let description = TranslationUnit.getMessage(for: .RESET_BASKET_DESCRIPTION),
                   let dismiss = TranslationUnit.getMessage(for: .OPTION_DISMISS),
                   let reset = TranslationUnit.getMessage(for: .OPTION_RESET){
                    HStack {
                        Button(role: .destructive) {
                            showResetBasketAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text(msg)
                                    .font(.system(size: 16))
                                Spacer()
                            }
                        }
                        .alert(isPresented: $showResetBasketAlert) {
                            Alert(
                                title: Text(msg),
                                message: Text(description),
                                primaryButton: .cancel(Text(dismiss)),
                                secondaryButton: .destructive(Text(reset), action: mainViewModel.resetShoppingBasket)
                            )
                        }
                    }
                }
                
                if let msg = TranslationUnit.getMessage(for: .RESET_ALL),
                   let description = TranslationUnit.getMessage(for: .RESET_ALL_DESCRIPTION),
                   let dismiss = TranslationUnit.getMessage(for: .OPTION_DISMISS),
                   let reset = TranslationUnit.getMessage(for: .OPTION_RESET){
                    HStack {
                        Button(role: .destructive) {
                            showResetAllAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text(msg)
                                    .font(.system(size: 16))
                                Spacer()
                            }
                        }
                        .alert(isPresented: $showResetAllAlert) {
                            Alert(
                                title: Text(msg),
                                message: Text(description),
                                primaryButton: .cancel(Text(dismiss)),
                                secondaryButton: .destructive(Text(reset), action: mainViewModel.reset)
                            )
                        }
                    }
                }
            }
            .scrollDisabled(true)
            Divider()
            Spacer()
            
            Section(header: Text(TranslationUnit.getMessage(for: .HOW_TO_TITLE) ?? "Help")) {
                let helpURL: URL = {
                    var components = URLComponents(string: "https://myurl.com/help")!
                    components.queryItems = [
                        URLQueryItem(name: "language", value: UserDefaults.standard.getLanguage())
                    ]
                    return components.url ?? URL(string: "https://myurl.com/help")!
                }()
                
                NavigationLink {
                    HowToView(pdfURL: helpURL)
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text(TranslationUnit.getMessage(for: .HOW_TO_DESCRIPTION) ?? "User Guide")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .navigationTitle(TranslationUnit.getMessage(for: .SETTINGS_TITLE) ?? "Settings")
        .font(.title)
    }
}

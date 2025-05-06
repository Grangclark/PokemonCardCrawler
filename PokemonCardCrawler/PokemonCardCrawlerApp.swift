//
//  PokemonCardCrawlerApp.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI
import CoreData

// アプリのメインエントリポイントを更新 (PokemonCardCrawlerApp.swift)
@main
struct PokemonCardCrawlerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // macOSのウィンドウサイズを設定
                    NSApp.windows.first?.setFrame(NSRect(x: 0, y: 0, width: 1000, height: 700), display: true)
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("クローリング開始") {
                    NotificationCenter.default.post(name: .startCrawling, object: nil)
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
                
                Button("データベースをクリア") {
                    NotificationCenter.default.post(name: .clearDatabase, object: nil)
                }
                .keyboardShortcut("K", modifiers: [.command, .shift])
                
                Divider()
                
                Button("デッキコードで検索") {
                    // タブを切り替える
                    NotificationCenter.default.post(name: .switchToDeckTab, object: nil)
                }
                .keyboardShortcut("D", modifiers: [.command])
            }
        }
    }
}

// 追加の通知
extension Notification.Name {
    static let switchToDeckTab = Notification.Name("switchToDeckTab")
}

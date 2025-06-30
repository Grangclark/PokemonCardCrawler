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
                    
                    // アプリ起動時に初期データをチェック
                    persistenceController.insertSampleDataIfNeeded()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

// 追加の通知
extension Notification.Name {
    static let switchToDeckTab = Notification.Name("switchToDeckTab")
}

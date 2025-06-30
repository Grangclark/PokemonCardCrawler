//
//  ContentView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDPokemonCard.name, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<CDPokemonCard>
    
    var filteredCards: [CDPokemonCard] {
        if searchText.isEmpty {
            return Array(cards)
        } else {
            return cards.filter { card in
                guard !card.name.isEmpty else { return false }
                return card.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // カードデータベースタブ
            NavigationView {
                List {
                    ForEach(filteredCards, id: \.self) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            CardRowView(card: card)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "カード名で検索")
                .navigationTitle("カードデータベース")
                
                Text("カードを選択してください")
                    .foregroundColor(.secondary)
            }
            .tabItem {
                Label("カード", systemImage: "rectangle.stack")
            }
            .tag(0)
            
            // デッキビュータブ
            DeckView()
                .tabItem {
                    Label("デッキ", systemImage: "list.bullet")
                }
                .tag(1)
            
            // 新しいタブを追加
            SingleCardCrawlerView()
                .tabItem {
                    Label("カード追加", systemImage: "plus.circle")
                }
                .tag(2)
        }

        .onAppear {
            // アプリ起動時に初期データ確認
            checkAndInsertInitialData()
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // 初期データの確認と挿入
    private func checkAndInsertInitialData() {
        // データが空の場合は初期データを挿入
        if cards.isEmpty {
            print("初期データがありません。サンプルデータを挿入します。")
            PersistenceController.shared.insertSampleDataIfNeeded()
        }
    }
}


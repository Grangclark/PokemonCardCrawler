//
//  ContentView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI
import CoreData

// TabView追加
// ContentView.swiftを更新
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var crawlerViewModel = CrawlerViewModel()
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDPokemonCard.name, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<PokemonCardCrawler.CDPokemonCard>
    
    var filteredCards: [PokemonCardCrawler.CDPokemonCard] {
        if searchText.isEmpty {
            return Array(cards)
        } else {
            return cards.filter { card in
                // guard let name = card.name else { return false }
                guard !card.name.isEmpty else { return false }
                // return name.localizedCaseInsensitiveContains(searchText)
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
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            crawlerViewModel.startCrawling()
                        }) {
                            Label("クローリング開始", systemImage: "arrow.clockwise")
                        }
                    }
                }
                
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
        }
        .overlay(
            ZStack {
                if crawlerViewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("クローリング中: \(crawlerViewModel.progress)/\(crawlerViewModel.totalItems)")
                            .font(.headline)
                            .padding()
                        
                        Button("キャンセル") {
                            crawlerViewModel.cancelCrawling()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(radius: 10)
                    )
                }
            }
        )
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .startCrawling,
            object: nil,
            queue: .main) { _ in
                crawlerViewModel.startCrawling()
            }
        
        NotificationCenter.default.addObserver(
            forName: .clearDatabase,
            object: nil,
            queue: .main) { _ in
                deleteAllCards()
            }
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .startCrawling, object: nil)
        NotificationCenter.default.removeObserver(self, name: .clearDatabase, object: nil)
    }
    
    private func deleteAllCards() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPokemonCard.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
        } catch {
            print("Error deleting cards: \(error)")
        }
    }
}

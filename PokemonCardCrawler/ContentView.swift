//
//  ContentView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI
import CoreData

/*
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                    } label: {
                        Text(item.timestamp!, formatter: itemFormatter)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
*/

/*
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var crawlerViewModel = CrawlerViewModel()
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.name, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    var filteredCards: [Card] {
        if searchText.isEmpty {
            return Array(cards)
        } else {
            return cards.filter { card in
                guard let name = card.name else { return false }
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
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
            .navigationTitle("ポケモンカードデータベース")
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
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Card.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
        } catch {
            print("Error deleting cards: \(error)")
        }
    }
}
*/

// TabView追加
// ContentView.swiftを更新
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var crawlerViewModel = CrawlerViewModel()
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.name, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    var filteredCards: [Card] {
        if searchText.isEmpty {
            return Array(cards)
        } else {
            return cards.filter { card in
                guard let name = card.name else { return false }
                return name.localizedCaseInsensitiveContains(searchText)
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
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Card.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
        } catch {
            print("Error deleting cards: \(error)")
        }
    }
}

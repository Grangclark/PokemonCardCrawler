//
//  DeckView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI
import CoreData

struct DeckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var deckCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cardIDs: [String] = []
    
    var body: some View {
        VStack {
            HStack {
                TextField("デッキコードを入力", text: $deckCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                
                Button(action: loadDeck) {
                    Text("読み込み")
                }
                .disabled(deckCode.isEmpty || isLoading)
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if isLoading {
                ProgressView("デッキを読み込み中...")
                    .padding()
            } else if !cardIDs.isEmpty {
                ScrollView {
                    LazyVStack {
                        ForEach(fetchCards(for: cardIDs), id: \.self) { card in
                            CardRowView(card: card)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("デッキ読み込み")
    }
    
    private func loadDeck() {
        guard !deckCode.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        let parser = DeckCodeParser()
        parser.parseDeckCode(deckCode) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let ids):
                    if ids.isEmpty {
                        self.errorMessage = "デッキが見つかりませんでした"
                    } else {
                        self.cardIDs = ids
                        self.errorMessage = nil
                    }
                case .failure(let error):
                    self.errorMessage = "エラー: \(error.localizedDescription)"
                    self.cardIDs = []
                }
            }
        }
    }
    
    private func fetchCards(for cardIDs: [String]) -> [PokemonCardCrawler.CDPokemonCard] {
        let fetchRequest: NSFetchRequest<PokemonCardCrawler.CDPokemonCard> = PokemonCardCrawler.CDPokemonCard.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardID IN %@", cardIDs)
        
        do {
            let cards = try viewContext.fetch(fetchRequest)
            
            // 存在しないカードIDを特定
            let fetchedIDs = Set(cards.compactMap { $0.cardID })
            let missingIDs = Set(cardIDs).subtracting(fetchedIDs)
            
            if !missingIDs.isEmpty {
                print("データベースに存在しないカード: \(missingIDs)")
            }
            
            // カードをデッキリストの順序に並べ替え
            var orderedCards: [PokemonCardCrawler.CDPokemonCard] = []
            for id in cardIDs {
                if let card = cards.first(where: { $0.cardID == id }) {
                    orderedCards.append(card)
                }
            }
            
            return orderedCards
        } catch {
            print("カードの取得エラー: \(error)")
            return []
        }
    }
}

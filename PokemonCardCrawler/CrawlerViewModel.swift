//
//  CrawlerViewModel.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import Foundation
import SwiftUI
import CoreData

class CrawlerViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var progress = 0
    @Published var totalItems = 0
    
    private var crawler: CardCrawler?
    private var context: NSManagedObjectContext
    
    init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    func startCrawling() {
        guard !isLoading else { return }
        
        isLoading = true
        progress = 0
        
        // クローリング開始
        crawler = CardCrawler()
        crawler?.delegate = self
        crawler?.startCrawling()
    }
    
    func cancelCrawling() {
        crawler?.cancelCrawling()
        isLoading = false
    }
    
    private func saveCards(_ cardData: [CardData]) {
        let context = PersistenceController.shared.backgroundContext
        
        context.perform {
            for data in cardData {
                // 既存のカードを検索
                let fetchRequest: NSFetchRequest<PokemonCardCrawler.CDPokemonCard> = PokemonCardCrawler.CDPokemonCard.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "cardID == %@", data.cardID)
                
                do {
                    let existingCards = try context.fetch(fetchRequest)
                    let card: CDPokemonCard
                    
                    if let existingCard = existingCards.first {
                        // 既存のカードを更新
                        card = existingCard
                    } else {
                        // 新しいカードを作成
                        card = CDPokemonCard(context: context)
                    }
                    
                    // データを設定
                    card.cardID = data.cardID
                    card.name = data.name
                    card.imageURL = data.imageURL
                    card.pageURL = data.pageURL
                    card.expansion = data.expansion
                    card.rarity = data.rarity
                    card.cardType = data.cardType
                    // card.hp = Int16(data.hp ?? 0)
                    card.hp = data.hp != nil ? NSNumber(value: Int16(data.hp!)) : NSNumber(value: 0)
                    card.attack1 = data.attack1
                    card.attack2 = data.attack2
                    card.ability = data.ability
                    card.weakness = data.weakness
                    card.resistance = data.resistance
                    // card.retreatCost = Int16(data.retreatCost ?? 0)
                    card.retreatCost = data.retreatCost != nil ? NSNumber(value: Int16(data.retreatCost!)) : NSNumber(value: 0)
                    card.timestamp = Date()
                } catch {
                    print("保存エラー: \(error)")
                }
            }
            
            // 変更を保存
            if context.hasChanges {
                do {
                    try context.save()
                    print("\(cardData.count)枚のカードを保存しました")
                } catch {
                    print("コンテキスト保存エラー: \(error)")
                }
            }
        }
    }
}

extension CrawlerViewModel: CardCrawlerDelegate {
    func crawlerDidUpdateProgress(_ crawler: CardCrawler, currentPage: Int, totalPages: Int) {
        DispatchQueue.main.async {
            self.progress = currentPage
            self.totalItems = totalPages
        }
    }
    
    func crawler(_ crawler: CardCrawler, didFetchCards cards: [CardData]) {
        saveCards(cards)
    }
    
    func crawlerDidFinish(_ crawler: CardCrawler) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func crawler(_ crawler: CardCrawler, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            print("クローリングエラー: \(error)")
        }
    }
}

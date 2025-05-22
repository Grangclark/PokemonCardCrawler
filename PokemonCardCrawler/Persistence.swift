//
//  Persistence.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import CoreData
import SwiftUI

struct PersistenceController {
    // 共有インスタンス
    static let shared = PersistenceController()
    
    // Core Dataコンテナ
    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext
    
    // 初期化
    init() {
        // モデル名を正しく指定する
        container = NSPersistentContainer(name: "PokemonCardCrawler")
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Core Dataストアの読み込みに失敗: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // サンプルデータの挿入
    func insertSampleDataIfNeeded() {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<CDPokemonCard>(entityName: "CDPokemonCard")
        
        do {
            let count = try context.count(for: fetchRequest)
            print("既存のカード数: \(count)")
            
            if count == 0 {
                print("サンプルデータを挿入します")
                // サンプルデータを追加
                let newCard = CDPokemonCard(context: context)
                // non optional
                newCard.name = "ピカチュウex"
                newCard.cardID = "033/106"
                newCard.imageURL = "https://www.pokemon-card.com/assets/images/card_images/large/SV8/046373_P_PIKACHIXYUUEX.jpg"
                newCard.pageURL = "https://www.pokemon-card.com/card-search/details.php/card/46373/regu/XY"

                // optional
                newCard.ability = "がんばりハート"
                newCard.attack1 = "トパーズボルト"
                newCard.attack2 = ""
                newCard.cardType = "でんき"
                newCard.expansion = "超電ブレイカー"
                newCard.hp = NSNumber(value: 200)
                newCard.rarity = "RR"
                newCard.resistance = ""
                newCard.retreatCost = NSNumber(value: 1)
                newCard.weakness = "かくとう"
                 
                try context.save()
                print("サンプルデータを保存しました")
            }
        } catch {
            print("データチェックエラー: \(error)")
        }
    }
}

// PokemonCardCrawler.xcdatamodeld
// CoreDataモデルは以下の属性を持つEntityを作成します
/*
Entity: Card
- cardID: String
- name: String
- imageURL: String
- pageURL: String
- expansion: String (optional)
- rarity: String (optional)
- cardType: String (optional)
- hp: Int16 (optional)
- attack1: String (optional)
- attack2: String (optional)
- ability: String (optional)
- weakness: String (optional)
- resistance: String (optional)
- retreatCost: Int16 (optional)
- timestamp: Date (optional)
*/

// デッキコードパーサー
class DeckCodeParser {
    private let baseURL = "https://www.pokemon-card.com/deck/deckView.php/deckID/"
    
    func parseDeckCode(_ deckCode: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: baseURL + deckCode) else {
            completion(.failure(NSError(domain: "無効なデッキコード", code: -1, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "無効なレスポンス", code: -2, userInfo: nil)))
                return
            }
            
            // HTMLからカードIDを抽出
            do {
                let cardIDs = try self.extractCardIDs(from: htmlString)
                completion(.success(cardIDs))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func extractCardIDs(from html: String) throws -> [String] {
        // デッキリストのカードIDを抽出する正規表現パターン
        // 注意: 実際のHTMLによって調整が必要
        let pattern = "card_id=\"([a-zA-Z0-9-]+)\""
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var cardIDs: [String] = []
            for match in matches {
                if match.numberOfRanges > 1 {
                    let cardID = nsString.substring(with: match.range(at: 1))
                    cardIDs.append(cardID)
                }
            }
            
            return cardIDs
        } catch {
            throw error
        }
    }
}

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
                newCard.name = "ピカチュウ"
                newCard.cardID = "001/xxx"
                newCard.expansion = "基本セット"
                newCard.hp = NSNumber(value: 70)
                newCard.cardType = "でんき"
                newCard.attack1 = "10ボルト"
                
                try context.save()
                print("サンプルデータを保存しました")
            }
        } catch {
            print("データチェックエラー: \(error)")
        }
    }
}

/*
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        // "PokemonCardModel"を"PokemonCardCrawler"に変更
        container = NSPersistentContainer(name: "PokemonCardCrawler")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreDataコンテナの読み込みエラー: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
*/

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

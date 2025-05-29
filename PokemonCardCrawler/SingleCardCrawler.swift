//
//  SingleCardCrawler.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/29.
//

import Foundation
import CoreData

// 仮の実装（実際のHTMLパース処理に置き換えてください）
struct CardInfo {
    let cardID: String
    let name: String
    let imageURL: String
    let pageURL: String
    let expansion: String?
    let rarity: String?
    let cardType: String?
    let hp: Int?
    let attack1: String?
    let attack2: String?
    let ability: String?
    let weakness: String?
    let resistance: String?
    let retreatCost: Int?
}

class SingleCardCrawler {
    static let shared = SingleCardCrawler()
    
    private init() {}
    
    func crawlSingleCard(url: String, context: NSManagedObjectContext, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let url = URL(string: url) else {
            completion(.failure(CrawlerError.invalidURL))
            return
        }
        
        // URLSessionでHTTPリクエストを実行
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                completion(.failure(CrawlerError.noData))
                return
            }
            
            // HTMLを解析してカード情報を抽出
            do {
                let cardInfo = try self.parseCardHTML(html)
                
                // Core Dataに保存
                context.perform {
                    let newCard = CDPokemonCard(context: context)
                    newCard.cardID = cardInfo.cardID
                    newCard.name = cardInfo.name
                    newCard.imageURL = cardInfo.imageURL
                    newCard.pageURL = cardInfo.pageURL
                    newCard.expansion = cardInfo.expansion
                    newCard.rarity = cardInfo.rarity
                    newCard.cardType = cardInfo.cardType
                    newCard.hp = cardInfo.hp != nil ? NSNumber(value: Int16(cardInfo.hp!)) : NSNumber(value: 0)
                    newCard.attack1 = cardInfo.attack1
                    newCard.attack2 = cardInfo.attack2
                    newCard.ability = cardInfo.ability
                    newCard.weakness = cardInfo.weakness
                    newCard.resistance = cardInfo.resistance
                    newCard.retreatCost = cardInfo.retreatCost != nil ? NSNumber(value: Int16(cardInfo.retreatCost!)) : NSNumber(value: 0)
                    
                    do {
                        try context.save()
                        completion(.success(cardInfo.name))
                    } catch {
                        completion(.failure(error))
                    }
                }
                
            } catch {
                completion(.failure(error))
            }
            
        }.resume()
    }
    
    private func parseCardHTML(_ html: String) throws -> CardInfo {
        // HTMLパース処理をここに実装
        // 既存のクローラーコードを参考に、1枚分の処理を行う
        
        // HTMLから必要な情報を抽出する処理
        // 正規表現やSwiftSoupを使用してパース
        
        return CardInfo(
            cardID: "033/106",
            name: "ピカチュウex",
            imageURL: "https://www.pokemon-card.com/card-search/details.php/card/46373/regu/XY",
            pageURL: "https://www.pokemon-card.com/assets/images/card_images/large/SV8/046373_P_PIKACHIXYUUEX.jpg",
            expansion: "超電ブレイカー",
            rarity: "RR",
            cardType: "でんき",
            hp: 200,
            attack1: "トパーズボルト",
            attack2: "",
            ability: "がんばりハート",
            weakness: "かくとう",
            resistance: "",
            retreatCost: 1
        )
    }
}

enum CrawlerError: Error {
    case invalidURL
    case noData
    case parseError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データを取得できませんでした"
        case .parseError:
            return "データの解析に失敗しました"
        }
    }
}

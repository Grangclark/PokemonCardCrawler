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
        
        // デバッグ: 入力されたURLを確認
        print("入力されたURL: \(url)")
        
        guard let url = URL(string: url) else {
            completion(.failure(CrawlerError.invalidURL))
            return
        }
        
        print("変換後のURL: \(url)")
        
        // 試験的にUser-Agentを追加
        // URLSessionでHTTPリクエストを実行
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        // URLSessionでHTTPリクエストを実行
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // デバッグ: レスポンス情報を確認
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTPステータスコード: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("ネットワークエラー: \(error)")
                print("エラーの詳細: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
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
                // let cardInfo = try self.parseCardHTML(html)
                let cardInfo = try self.parseCardHTML(html, url: url.absoluteString) // URL引数を追加
                
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
    
    private func parseCardHTML(_ html: String, url: String) throws -> CardInfo {
        
         /*
         // サンプルなので消すな
        return CardInfo(
            cardID: "033/106",
            name: "ピカチュウex",
            pageURL: "https://www.pokemon-card.com/card-search/details.php/card/46373/regu/XY",
            imageURL: "https://www.pokemon-card.com/assets/images/card_images/large/SV8/046373_P_PIKACHIXYUUEX.jpg",
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
         */
        
        print("=== HTMLパース開始 ===")
            
        // Phase 1: 確実に取得できる基本情報のみ
            
        // 1. カード名
        let namePattern = #"<h1[^>]*class="Heading1[^"]*"[^>]*>(.*?)</h1>"#
        let name = extractValue(from: html, pattern: namePattern) ?? "不明なカード"
        print("カード名: \(name)")
        
        // 2. HP
        let hpPattern = #"<span[^>]*class="hp-num"[^>]*>(\d+)</span>"#
        let hpString = extractValue(from: html, pattern: hpPattern) ?? "0"
        let hp = Int(hpString) ?? 0
        print("HP: \(hp)")
        
        // 3. 進化段階（一時的にコメントアウト - Core Dataにフィールドなし）
        // let evolutionPattern = #"<span[^>]*class="type"[^>]*>(.*?)</span>"#
        // let evolution = extractValue(from: html, pattern: evolutionPattern) ?? ""
        // print("進化段階: \(evolution)")
        
        // 4. 特性名
        let abilityPattern = #"<h2[^>]*>特性</h2>\s*<h4[^>]*>(.*?)</h4>"#
        let ability = extractValue(from: html, pattern: abilityPattern) ?? ""
        print("特性: \(ability)")
        
        // 5. 技名（アイコンタグを除いて技名のみ抽出）
        let attackPattern = #"<h2[^>]*>ワザ</h2>\s*<h4[^>]*>.*?</span>([^<]+)<span[^>]*f_right"#
        let rawAttack = extractValue(from: html, pattern: attackPattern) ?? ""
        let attack1 = rawAttack.trimmingCharacters(in: .whitespacesAndNewlines)
        print("技1: \(attack1)")
        
        // 6. 画像URL
        let imagePattern = #"<img[^>]*class="fit"[^>]*src="([^"]*)"#
        let imageURL = extractValue(from: html, pattern: imagePattern) ?? ""
        print("画像URL: \(imageURL)")
        
        print("=== HTMLパース完了 ===")
        
        // 難しい情報は全て固定値またはコメントアウト
        return CardInfo(
            cardID: "Phase2で実装予定", // Phase 2で実装
            name: name,
            imageURL: imageURL,
            pageURL: url,
            expansion: "Phase2で実装予定", // Phase 2で実装
            rarity: "Phase3で実装予定", // Phase 3で実装（アイコン処理）
            cardType: "Phase3で実装予定", // Phase 3で実装（アイコン処理）
            hp: hp,
            attack1: attack1,
            attack2: "", // Phase 2で複数技対応
            ability: ability,
            weakness: "Phase3で実装予定", // Phase 3で実装（アイコン処理）
            resistance: "Phase3で実装予定", // Phase 3で実装（アイコン処理）
            retreatCost: 0 // Phase 3で実装（アイコン処理）
        )
    }
}

// 正規表現を使って値を抽出するヘルパーメソッド
private func extractValue(from html: String, pattern: String) -> String? {
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first, match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            let extractedValue = nsString.substring(with: range)
            // HTMLエンティティをデコードして、余分な空白を除去
            return cleanHTMLString(extractedValue)
        }
    } catch {
        print("正規表現エラー: \(error)")
    }
    return nil
}

// HTMLエンティティのデコードと文字列のクリーンアップ
private func cleanHTMLString(_ html: String) -> String {
    return html
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .trimmingCharacters(in: .whitespacesAndNewlines)
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

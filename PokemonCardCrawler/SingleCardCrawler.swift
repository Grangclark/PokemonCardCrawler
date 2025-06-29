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
        
        /*
        // 5. 技名（アイコンタグを除いて技名のみ抽出）
        let attackPattern = #"<h2[^>]*>ワザ</h2>\s*<h4[^>]*>.*?</span>([^<]+)<span[^>]*f_right"#
        let rawAttack = extractValue(from: html, pattern: attackPattern) ?? ""
        let attack1 = rawAttack.trimmingCharacters(in: .whitespacesAndNewlines)
        print("技1: \(attack1)")
        */
         
        // 6. 画像URL
        let imagePattern = #"<img[^>]*class="fit"[^>]*src="([^"]*)"#
        let imageURL = extractValue(from: html, pattern: imagePattern) ?? ""
        print("画像URL: \(imageURL)")
        
        // ===== Phase 2: 新規実装 =====
        
        // 7. CardID（122/106形式の特殊文字処理）
        let cardIDPattern = #"&nbsp;(\d+)&nbsp;/&nbsp;(\d+)&nbsp;"#
        let cardID = extractCardID(from: html)
        print("カードID: \(cardID)")
        
        // 8. 拡張パック名（SV8の抽出）
        let expansionPattern = #"src="/assets/images/card/regulation_logo_1/([^\.]+)\.gif""#
        let expansion = extractValue(from: html, pattern: expansionPattern) ?? ""
        print("拡張パック: \(expansion)")
        
        // 9. 技1（アイコンタグを除いて技名のみ抽出 + ダメージ）
        let (attack1Name, attack1Damage) = extractAttackInfo(from: html, attackNumber: 1)
        let attack1Final = attack1Damage > 0 ? "\(attack1Name)(\(attack1Damage))" : attack1Name
        print("技1: \(attack1Final)")
        
        // 10. 技2（複数技への対応）
        let (attack2Name, attack2Damage) = extractAttackInfo(from: html, attackNumber: 2)
        let attack2Final = attack2Damage > 0 ? "\(attack2Name)(\(attack2Damage))" : attack2Name
        print("技2: \(attack2Final)")
        
        print("=== HTMLパース完了 ===")
        
        return CardInfo(
            cardID: cardID,
            name: name,
            imageURL: imageURL,
            pageURL: url,
            expansion: expansion.isEmpty ? nil : expansion,
            rarity: "Phase3で実装予定", // Phase 3で実装（アイコン処理）
            cardType: "Phase3で実装予定", // Phase 3で実装（アイコン処理）
            hp: hp > 0 ? hp : nil,
            attack1: attack1Final.isEmpty ? nil : attack1Final,
            attack2: attack2Final.isEmpty ? nil : attack2Final,
            ability: ability.isEmpty ? nil : ability,
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

// MARK: - Phase 2 新規ヘルパーメソッド

// CardID抽出（特殊文字&nbsp;の処理）
private func extractCardID(from html: String) -> String {
    let pattern = #"&nbsp;(\d+)&nbsp;/&nbsp;(\d+)&nbsp;"#
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first, match.numberOfRanges >= 3 {
            let firstNumber = nsString.substring(with: match.range(at: 1))
            let secondNumber = nsString.substring(with: match.range(at: 2))
            return "\(firstNumber)/\(secondNumber)"
        }
    } catch {
        print("CardID抽出エラー: \(error)")
    }
    return ""
}

// 技の情報抽出（技名 + ダメージ）
private func extractAttackInfo(from html: String, attackNumber: Int) -> (name: String, damage: Int) {
    // まず全ての技のh4タグを抽出
    let allAttacksPattern = #"<h2[^>]*>ワザ</h2>(.*?)(?=<h2|<table|$)"#
    
    guard let attacksSection = extractValue(from: html, pattern: allAttacksPattern) else {
        return ("", 0)
    }
    
    // 技のh4タグを個別に抽出
    let individualAttackPattern = #"<h4[^>]*>(.*?)</h4>"#
    let attackMatches = extractAllMatches(from: attacksSection, pattern: individualAttackPattern)
    
    // 指定された番号の技を取得
    guard attackNumber <= attackMatches.count, attackNumber > 0 else {
        return ("", 0)
    }
    
    let attackHTML = attackMatches[attackNumber - 1]
    
    // 技名の抽出（アイコンを除去）
    let namePattern = #"</span>([^<]+)<span[^>]*f_right"#
    let attackName = extractValue(from: attackHTML, pattern: namePattern)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    
    // ダメージの抽出
    let damagePattern = #"<span[^>]*f_right[^>]*>(\d+)</span>"#
    let damageString = extractValue(from: attackHTML, pattern: damagePattern) ?? "0"
    let damage = Int(damageString) ?? 0
    
    return (attackName, damage)
}

// 複数のマッチを抽出するヘルパーメソッド
private func extractAllMatches(from text: String, pattern: String) -> [String] {
    var matches: [String] = []
    
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in results {
            if match.numberOfRanges > 1 {
                let matchedString = nsString.substring(with: match.range(at: 1))
                matches.append(matchedString)
            }
        }
    } catch {
        print("複数マッチ抽出エラー: \(error)")
    }
    
    return matches
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

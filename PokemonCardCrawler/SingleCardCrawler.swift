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
        // HTMLパース処理をここに実装
        // 既存のクローラーコードを参考に、1枚分の処理を行う
        
        // カードIDの抽出（例：001/165）
        let cardIDPattern = #"<span[^>]*class=".*cardNumber.*"[^>]*>(.*?)</span>"#
        let cardID = extractValue(from: html, pattern: cardIDPattern) ?? "000/000"
        
        // カード名の抽出
        let namePattern = #"<h1[^>]*class=".*cardName.*"[^>]*>(.*?)</h1>"#
        let name = extractValue(from: html, pattern: namePattern) ?? "不明なカード"
        
        // 画像URLの抽出
        let imageURLPattern = #"<img[^>]*class=".*cardImage.*"[^>]*src="([^"]*)"#
        let imageURL = extractValue(from: html, pattern: imageURLPattern) ?? ""

        // pageURLは引数として渡されたURLをそのまま使用
        // let pageURL = url // crawlSingleCard関数の引数として渡されたURL
        
        // 拡張パック名の抽出
        let expansionPattern = #"<span[^>]*class=".*expansionPack.*"[^>]*>(.*?)</span>"#
        let expansion = extractValue(from: html, pattern: expansionPattern) ?? "不明な拡張パック"
        
        // レアリティの抽出
        let rarityPattern = #"<span[^>]*class=".*rarity.*"[^>]*>(.*?)</span>"#
        let rarity = extractValue(from: html, pattern: rarityPattern) ?? ""
        
        // タイプの抽出
        let typePattern = #"<span[^>]*class=".*type.*"[^>]*>(.*?)</span>"#
        let cardType = extractValue(from: html, pattern: typePattern) ?? "ノーマル"
        
        // HPの抽出
        let hpPattern = #"<span[^>]*class=".*hp.*"[^>]*>.*?(\d+)</span>"#
        let hpString = extractValue(from: html, pattern: hpPattern) ?? "0"
        let hp = Int(hpString) ?? 0
        
        // 技1の抽出
        let attack1Pattern = #"<div[^>]*class=".*attack.*"[^>]*>.*?<span[^>]*class=".*attackName.*"[^>]*>(.*?)</span>"#
        let attack1 = extractValue(from: html, pattern: attack1Pattern) ?? ""
        
        // 技2の抽出（複数の技がある場合）
        let attack2Pattern = #"<div[^>]*class=".*attack.*"[^>]*>.*?<div[^>]*class=".*attack.*"[^>]*>.*?<span[^>]*class=".*attackName.*"[^>]*>(.*?)</span>"#
        let attack2 = extractValue(from: html, pattern: attack2Pattern) ?? ""
        
        // 特性の抽出
        let abilityPattern = #"<span[^>]*class=".*ability.*"[^>]*>(.*?)</span>"#
        let ability = extractValue(from: html, pattern: abilityPattern) ?? ""
        
        // 弱点の抽出
        let weaknessPattern = #"<span[^>]*class=".*weakness.*"[^>]*>(.*?)</span>"#
        let weakness = extractValue(from: html, pattern: weaknessPattern) ?? ""
        
        // 抵抗力の抽出
        let resistancePattern = #"<span[^>]*class=".*resistance.*"[^>]*>(.*?)</span>"#
        let resistance = extractValue(from: html, pattern: resistancePattern) ?? ""
        
        // 逃げるエネルギーの抽出
        let retreatPattern = #"<span[^>]*class=".*retreat.*"[^>]*>.*?(\d+)"#
        let retreatString = extractValue(from: html, pattern: retreatPattern) ?? "0"
        let retreatCost = Int(retreatString) ?? 0
        
        /*
        // 進化段階の抽出
        let evolutionPattern = #"<span[^>]*class=".*evolution.*"[^>]*>(.*?)</span>"#
        let evolution = extractValue(from: html, pattern: evolutionPattern) ?? ""
        */

        print("パース結果:")
        print("カードID: \(cardID)")
        print("名前: \(name)")
        print("拡張パック: \(expansion)")
        print("レアリティ: \(rarity)")
        print("タイプ: \(cardType)")
        print("HP: \(hp)")
        print("技1: \(attack1)")
        print("技2: \(attack2)")
        print("特性: \(ability)")
        print("弱点: \(weakness)")
        print("抵抗力: \(resistance)")
        print("逃げるコスト: \(retreatCost)")
        
        return CardInfo(
            cardID: cardID,
            name: name,
            imageURL: imageURL,
            pageURL: url, // 引数として受け取ったURLを設定
            expansion: expansion,
            rarity: rarity,
            cardType: cardType,
            hp: hp,
            attack1: attack1,
            attack2: attack2,
            ability: ability,
            weakness: weakness,
            resistance: resistance,
            retreatCost: retreatCost
        )
        
        // HTMLから必要な情報を抽出する処理
        // 正規表現やSwiftSoupを使用してパース
        
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

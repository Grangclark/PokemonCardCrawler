//
//  CardCrawler.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import Foundation

struct CardData {
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

protocol CardCrawlerDelegate: AnyObject {
    func crawlerDidUpdateProgress(_ crawler: CardCrawler, currentPage: Int, totalPages: Int)
    func crawler(_ crawler: CardCrawler, didFetchCards cards: [CardData])
    func crawlerDidFinish(_ crawler: CardCrawler)
    func crawler(_ crawler: CardCrawler, didFailWithError error: Error)
}

class CardCrawler {
    weak var delegate: CardCrawlerDelegate?
    private var isCancelled = false
    private let baseURL = "https://www.pokemon-card.com"
    private let cardsPerPage = 24
    private let delayBetweenRequests: TimeInterval = 2.0 // サーバー負荷を減らすための遅延（秒）
    
    // クローリングを開始
    func startCrawling() {
        isCancelled = false
        // まず全体のカード数を取得するためにインデックスページを取得
        fetchTotalCardCount { [weak self] totalCount in
            guard let self = self, !self.isCancelled else { return }
            
            let totalPages = (totalCount + self.cardsPerPage - 1) / self.cardsPerPage
            self.delegate?.crawlerDidUpdateProgress(self, currentPage: 0, totalPages: totalPages)
            
            self.crawlCardsSequentially(currentPage: 1, totalPages: totalPages)
        }
    }
    
    // クローリングをキャンセル
    func cancelCrawling() {
        isCancelled = true
    }
    
    // 全カード数を取得
    private func fetchTotalCardCount(completion: @escaping (Int) -> Void) {
        let urlString = "\(baseURL)/card-search/index.php"
        guard let url = URL(string: urlString) else {
            delegate?.crawler(self, didFailWithError: NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, !self.isCancelled else { return }
            
            if let error = error {
                self.delegate?.crawler(self, didFailWithError: error)
                return
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                self.delegate?.crawler(self, didFailWithError: NSError(domain: "Invalid data", code: -2, userInfo: nil))
                return
            }
            
            // 総カード数を見つける正規表現（実際のHTMLに合わせて調整が必要）
            // 例: "検索結果：1000件" のような文字列から数値を抽出
            let pattern = "検索結果：([0-9,]+)件"
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = htmlString as NSString
                let matches = regex.matches(in: htmlString, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first {
                    let countString = nsString.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: "")
                    if let count = Int(countString) {
                        completion(count)
                        return
                    }
                }
                
                // 見つからない場合は推定値で進める
                completion(1000) // 仮の値
            } catch {
                self.delegate?.crawler(self, didFailWithError: error)
            }
        }.resume()
    }
    
    // ページごとに順番にクローリング
    private func crawlCardsSequentially(currentPage: Int, totalPages: Int) {
        guard !isCancelled, currentPage <= totalPages else {
            if !isCancelled {
                delegate?.crawlerDidFinish(self)
            }
            return
        }
        
        delegate?.crawlerDidUpdateProgress(self, currentPage: currentPage, totalPages: totalPages)
        
        fetchCardList(page: currentPage) { [weak self] cardUrls in
            guard let self = self, !self.isCancelled else { return }
            
            let group = DispatchGroup()
            var cardDataList: [CardData] = []
            
            for (index, cardUrl) in cardUrls.enumerated() {
                group.enter()
                
                // リクエスト間に遅延を入れる
                DispatchQueue.global().asyncAfter(deadline: .now() + self.delayBetweenRequests * Double(index)) {
                    self.fetchCardDetail(url: cardUrl) { cardData in
                        if let cardData = cardData {
                            cardDataList.append(cardData)
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                guard !self.isCancelled else { return }
                
                if !cardDataList.isEmpty {
                    self.delegate?.crawler(self, didFetchCards: cardDataList)
                }
                
                // 次のページへ
                self.crawlCardsSequentially(currentPage: currentPage + 1, totalPages: totalPages)
            }
        }
    }
    
    // カードリストページを取得
    private func fetchCardList(page: Int, completion: @escaping ([String]) -> Void) {
        let urlString = "\(baseURL)/card-search/index.php?page=\(page)"
        guard let url = URL(string: urlString) else {
            delegate?.crawler(self, didFailWithError: NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, !self.isCancelled else {
                completion([])
                return
            }
            
            if let error = error {
                self.delegate?.crawler(self, didFailWithError: error)
                completion([])
                return
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                self.delegate?.crawler(self, didFailWithError: NSError(domain: "Invalid data", code: -2, userInfo: nil))
                completion([])
                return
            }
            
            // カード詳細へのリンクを抽出する正規表現（実際のHTMLに合わせて調整が必要）
            let pattern = "href=\"(.*?card-detail.*?)\""
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let nsString = htmlString as NSString
                let matches = regex.matches(in: htmlString, options: [], range: NSRange(location: 0, length: nsString.length))
                
                let cardUrls = matches.map { match -> String in
                    let path = nsString.substring(with: match.range(at: 1))
                    return self.baseURL + path
                }
                
                completion(cardUrls)
            } catch {
                self.delegate?.crawler(self, didFailWithError: error)
                completion([])
            }
        }.resume()
    }
    
    // カード詳細ページを取得
    private func fetchCardDetail(url: String, completion: @escaping (CardData?) -> Void) {
        guard let url = URL(string: url) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, !self.isCancelled else {
                completion(nil)
                return
            }
            
            if let error = error {
                print("カード詳細取得エラー: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            // HTMLからカード情報を抽出
            let cardData = self.parseCardDetail(html: htmlString, pageURL: url.absoluteString)
            completion(cardData)
        }.resume()
    }
    
    // HTML解析してカード情報を抽出
    private func parseCardDetail(html: String, pageURL: String) -> CardData? {
        // カードIDを抽出（例: c=カード&p=sm9-XXX）
        let idPattern = "c=.+?&p=([a-zA-Z0-9-]+)"
        guard let cardID = extractRegex(pattern: idPattern, from: html, groupIndex: 1) else {
            return nil
        }
        
        // カード名を抽出
        let namePattern = "<h1[^>]*>([^<]+)</h1>"
        guard let name = extractRegex(pattern: namePattern, from: html, groupIndex: 1) else {
            return nil
        }
        
        // カード画像URLを抽出
        let imagePattern = "(https://www.pokemon-card.com/assets/images/card_images/large/[^\"']+\\.(jpg|png))"
        let imageURL = extractRegex(pattern: imagePattern, from: html, groupIndex: 1) ?? ""
        
        // 拡張セット
        let expansionPattern = "拡張パック：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let expansion = extractRegex(pattern: expansionPattern, from: html, groupIndex: 1)
        
        // レアリティ
        let rarityPattern = "レアリティ：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let rarity = extractRegex(pattern: rarityPattern, from: html, groupIndex: 1)
        
        // カードタイプ
        let typePattern = "カードタイプ：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let cardType = extractRegex(pattern: typePattern, from: html, groupIndex: 1)
        
        // HP
        let hpPattern = "HP：</dt>\\s*<dd[^>]*>([0-9]+)</dd>"
        let hpStr = extractRegex(pattern: hpPattern, from: html, groupIndex: 1)
        let hp = hpStr != nil ? Int(hpStr!) : nil
        
        // 技1
        let attack1Pattern = "技1：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let attack1 = extractRegex(pattern: attack1Pattern, from: html, groupIndex: 1)
        
        // 技2
        let attack2Pattern = "技2：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let attack2 = extractRegex(pattern: attack2Pattern, from: html, groupIndex: 1)
        
        // 特性
        let abilityPattern = "特性：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let ability = extractRegex(pattern: abilityPattern, from: html, groupIndex: 1)
        
        // 弱点
        let weaknessPattern = "弱点：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let weakness = extractRegex(pattern: weaknessPattern, from: html, groupIndex: 1)
        
        // 抵抗力
        let resistancePattern = "抵抗力：</dt>\\s*<dd[^>]*>([^<]+)</dd>"
        let resistance = extractRegex(pattern: resistancePattern, from: html, groupIndex: 1)
        
        // 逃げるコスト
        let retreatPattern = "逃げるコスト：</dt>\\s*<dd[^>]*>([0-9]+)</dd>"
        let retreatStr = extractRegex(pattern: retreatPattern, from: html, groupIndex: 1)
        let retreatCost = retreatStr != nil ? Int(retreatStr!) : nil
        
        return CardData(
            cardID: cardID,
            name: name,
            imageURL: imageURL,
            pageURL: pageURL,
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
    }
    
    // 正規表現でHTMLから情報を抽出するヘルパーメソッド
    private func extractRegex(pattern: String, from text: String, groupIndex: Int) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > groupIndex {
                return nsString.substring(with: match.range(at: groupIndex))
            }
            return nil
        } catch {
            print("正規表現エラー: \(error)")
            return nil
        }
    }
}

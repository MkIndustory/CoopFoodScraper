//
//  main.swift
//  CoopFoodScraper
//
//  Created by ぴっきー！ on 2024/02/04.
//

import Foundation
import Alamofire
import SwiftSoup

@main
struct CoopFoodScraper {
    // システムメンテナンス中は以下から取れる。
    // https://west2-univ.jp/sp/index.php?t=650111
    /*
     京都大学中央食堂の場合
     　主菜：on_a
     　副菜：on_b
     　麺類：on_c
     　丼・カレー：on_d
     　デザート：on_e
     　夜限定メニュー：on_bunrui2
     */
    static let homeUrlString = "https://west2-univ.jp/sp/index.php?t=650111"
    static var urlsArray = [
        "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_a",
        "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_b",
        "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_c",
        "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_d",
        "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_e",
        "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_bunrui2"
    ]

    static func getHomeState() async throws -> Bool? {
        let response = await AF.request(homeUrlString, 
                                        method: .get,
                                        headers: nil).serializingString().response
        guard let html = response.value, let doc = try? SwiftSoup.parse(html) else {
            print("HTMLパース失敗")
            return nil}
        
        //liタグの一番最初を取得
        let li = try? doc.select("li").array().first
        guard let text = try? li?.text() else {
            print("liからtextとるの失敗")
            return nil}
        print("📃",text) //システムメンテナンス中の場合、"現在、システムメンテナンス中です #1" となるはず
        return text.contains("システムメンテナンス中")
    }
        
    static func main() async throws {
        let isMaintenanceMode = try await getHomeState() ?? true
        // システムメンテナンス中やなにかがおかしい場合、 isMaintenanceMode == true
        // その場合は新しいjsonを作らない。
        guard !isMaintenanceMode else {return}
        for url in urlsArray {
            
            var foodNameArray : [String] = []
            var priceArray : [String] = []
            var foodsArray : [Food] = []
            
            let response = await AF.request(url, method: .get, headers: nil).serializingString().response
            guard let html = response.value, let doc = try? SwiftSoup.parse(html) else {return }
                    
            //画像を取得
            let srcs: Elements = try doc.select("img[src]")
            var srcsStringArray: [String] = srcs.array().map { try! $0.attr("src").description }
            //d(丼とカレーとご飯)の時だけ詳細画面のURLからご飯画像を取得するのでリセット。
            if url.hasSuffix("d") {
                srcsStringArray = []
            }
            
            //aタグを取得
            let linkArray = try doc.select("a").array()
            
            for i in 0..<linkArray.count {
                print(i,linkArray.count)
                //d(丼とカレーとご飯)の時だけ詳細画面のURLからサイズ情報を取得したい。
                if url.hasSuffix("d") {
                    let query = try linkArray[i].attr("href")
                    let detailURL = "https://west2-univ.jp/sp/" + query
                    print("🌷",detailURL) //https://west2-univ.jp/sp/detail.php?t=650111&c=814166
                    let response = await AF.request(detailURL,
                                                    method: .get,
                                                    headers: nil).serializingString().response
                    guard let html = response.value, let doc = try? SwiftSoup.parse(html) else {return }
                    let span = try? doc.select("li").first()?.select("span").array()
                    let priceString = try span?[1].text() // Optional("中115円 ﾐﾆ73円 小94円 大136円")
                    let priceAndSizeArray:[String] = priceString?.components(separatedBy: " ") ?? []
                    print("😍",priceAndSizeArray)
                    
                    for j in 0..<priceAndSizeArray.count {
                        //"円"の文字を消す
                        let price = priceAndSizeArray[j].replacingOccurrences(of:"円", with:"")
                        priceArray.append(price)
                    }
                    print(priceArray)
                    
                    // ここまででd用のpriceArrayができた。次はfoodNameArray
                    let h1 = try? doc.select("h1").array()[1]
                    let japaneseAndEnglish = try h1?.text()
                    print("🤩",japaneseAndEnglish) //サーモンビビンバ丼中Bowl of rice with raw salmon and vegetables in Korean chili sauce
                    //h3タグの中でspanタグを取得
                    let spanText = try? h1?.select("span").array().first?.text()
                    print("🤩", spanText)
                    // 英語の説明を消している
                    let japanese = japaneseAndEnglish?.replacingOccurrences(of:spanText!, with:"")
                    print("🤩",japanese)
                    // ここまでで日本語名ができた。料金バラエティの数だけfoodNameArrayにそのご飯の名前を入れる。
                    for j in 0..<priceAndSizeArray.count {
                        foodNameArray.append(japanese ?? "")
                    }
                    
                    let imgSrcs: Elements = try doc.select("img[src]")
                    let imgSrcsStringArray: [String] = imgSrcs.array().map { try! $0.attr("src").description }
                    let foodImageURL = imgSrcsStringArray[1]
                    print("⭕️",foodImageURL)
                    // 料金バラエティの数だけsrcsStringArrayにそのご飯の画像URLを入れる。
                    for j in 0..<priceAndSizeArray.count {
                        srcsStringArray.append(foodImageURL )
                    }
                    
                }
                
                //aタグの中でh3タグを取得
                let h3 = try? linkArray[i].select("h3").array()
 
                for string in h3 ?? [] {
                    guard let text = try? string.text() else {return }
                    print("❤️",text) //きつねそばHot buckwheat noodles with fried bean curd in Japanese soup¥319
                    
                    //h3タグの中でspanタグを取得
                    let span = try? string.select("span").array()
                    for paragraph in span ?? [] {
                        if let spanText = try? paragraph.text() {
                            print("😀",spanText) //Hot buckwheat noodles with fried bean curd in Japanese soup
                            // 英語の説明を消している
                            let japaneseAndYen = text.replacingOccurrences(of:spanText, with:"")
                            let arr:[String] = japaneseAndYen.components(separatedBy: "¥")
                            print("😔",arr[0],arr[1]) //きつねそば,¥319
                            
                            //dの時は既にfoodNAmeArrayとpriceArrayは出来上がっているので、d以外の時だけ実行
                            if !url.hasSuffix("d") {
                                foodNameArray.append(arr[0])
                                priceArray.append(arr[1])
                            }
                            break // "きつねそば¥319" というtextだけ欲しいのでfor文全部回さない
                        }
                    }
                }
            }
            
            print("☀️",foodNameArray.count, priceArray.count, srcsStringArray.count)
            // ここからjsonを作る。
            for i in 0 ..< foodNameArray.count {
                //JSON 化したいデータを 構造体 で作成
                let food = Food(name: foodNameArray[i],
                                price: priceArray[i],
                                img: srcsStringArray[i])
                foodsArray.append(food)
            }
            
            let encoder = JSONEncoder()
            // フォーマットを指定
            encoder.outputFormatting = .prettyPrinted
            // エンコード
            let jsonData = try encoder.encode(foodsArray)
            // 文字コードUTF8のData型に変換
            print("☔️",String(data: jsonData , encoding: .utf8)!)
            
            //このあとファイルに書き出す処理を書く。
            let dirURL = FileManager.default.currentDirectoryPath
            
            print("🌷",dirURL)
            print("💐",FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
            print("💦",FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
            //URLの最後の文字列を取得して一意なjsonを作る
            let lastCharacter = url.last!
            print("😤",lastCharacter)
            guard let fileURL = URL(string:"file://" + dirURL + "/ChuoFoodData\(lastCharacter).json") else {
                fatalError("fileURLエラー") }
            print(fileURL)
            do {
                try jsonData.write(to: fileURL)
            } catch {
                fatalError("JSON書き込みエラー")
            }
        }
    }
}



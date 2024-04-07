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
    // TODO: システムメンテナンス中かどうか判断するのは今のとこは中央食堂のみだけど、食堂ごとにみるようにしたい。
    // 全部の食堂へのページ：https://west2-univ.jp/sp/kyoto-univ.php
    static let homeUrlString = "https://west2-univ.jp/sp/index.php?t=650111"
    // 中央食堂のトップページ。システムメンテナンス中かどうかのみを判定する。
    
    /*
     京都大学中央食堂の場合
     　主菜：on_a
     　副菜：on_b
     　麺類：on_c
     　丼・カレー：on_d
     　デザート：on_e
     　夜限定メニュー：on_bunrui2
     トップページ：https://west2-univ.jp/sp/index.php?t=650111
     */
    
    /*
     京都大学吉田食堂の場合
     　主菜：on_a
     　副菜：on_b
     　丼・カレー：on_d
     　デザート：on_e
     トップページ：https://west2-univ.jp/sp/index.php?t=650112
     */
    
    /*
     ルネの場合
     　主菜：on_a
     　副菜：on_b
     　丼・カレー：on_d
     　デザート：on_e
     　オーダー：on_bunrui1
     　ケバブ＆ベジタリアン：on_bunrui2
     　パフェ：on_bunrui3
     トップページ：https://west2-univ.jp/sp/index.php?t=650118
     */
    
    /*
     宇治の場合
     　主菜：on_a
     　副菜：on_b
     　丼・カレー：on_d
     　デザート：on_e
     　昼の日替わり主菜：on_bunrui1
     　夜の日替わり主菜：on_bunrui2
     　　　　夜の丼ぶり：on_bunrui3
     トップページ：https://west2-univ.jp/sp/index.php?t=650116
     */
    
    /*
     京都大学桂セレネの場合
     　主菜：on_a
     　副菜：on_b
     　麺類：on_c
     　丼・カレー：on_d
     　デザート：on_e
     　昼の日替わり主菜：on_bunrui1
     　夜の日替わり主菜：on_bunrui2
     トップページ：https://west2-univ.jp/sp/index.php?t=650120
     */
    
    
    /*
     北部の場合
     　主菜：on_a
     　副菜：on_b
     　丼・カレー：on_d
     　デザート：on_e
     　昼　オーダーコーナー：on_bunrui1
     　夜　丼・オーダーコーナー：on_bunrui2
     トップページ：https://west2-univ.jp/sp/index.php?t=650113
     */
    
    /*
     南部の場合
     　主菜：on_a
     　副菜：on_b
     トップページ：https://west2-univ.jp/sp/index.php?t=650115
     */
    
    // すなわちバリエーションは。
    //on_bunrui1 "昼　オーダーコーナー"(北部) "昼の日替わり主菜"(桂と宇治) "オーダー"(ルネ)
    //on_bunrui2 "夜　丼・オーダーコーナー"(北部) "夜の日替わり主菜"(桂と宇治) "ケバブ＆ベジタリアン"(ルネ) "夜限定メニュー"(中央)
    //on_bunrui3 "夜の丼ぶり" (宇治) "パフェ"(ルネ)
    
    static let cafeDict = ["Chuo":"650111",
                           "Yoshida":"650112",
                           "Hokubu":"650113",
                           "Nambu":"650115",
                           "Uji":"650116",
                           "Rune":"650118",
                           "Katsura":"650120",
                           "Ortus":"650711",
                           "Bistro":"650911",
                           "Kyoyu":"650913",
    ]
    
    
    static func main() async throws {
        let isMaintenanceMode = try await getHomeState() ?? true
        // システムメンテナンス中やなにかがおかしい場合、 isMaintenanceMode == true
        // その場合は新しいjsonを作らない。
        guard !isMaintenanceMode else {return}
        let keys = Array(cafeDict.keys) // ["Chuo" ,"Yoshida", ...]
        
        
        var cafesArray : [Menu] = []
        
        for key in keys {
            let menusArray : [Menu] = try await getCafeData(cafeName:key)
            cafesArray += menusArray
        }
        
        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .long
//        dateFormatter.timeStyle = .short
//
//        // 日本の日付表示
//        dateFormatter.locale = Locale(identifier: "ja_JP")
//        let japaneseDate = dateFormatter.string(from: Date())
        
        // 加算する時間（秒）
        let addSec: Double = 60 * 60 * 9 // 9時間　加算
        let nowTime = Date(timeIntervalSinceNow: addSec)
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_jp")
        let now = dateFormatter.string(from: nowTime)
        
        //JSON 化したいデータを 構造体 で作成
        let univ = Univ(time: now,//japaneseDate,
                        cafes: cafesArray)
        
                let encoder = JSONEncoder()
                // フォーマットを指定
                encoder.outputFormatting = .prettyPrinted
                // エンコード
                let jsonData = try encoder.encode(univ)
                // 文字コードUTF8のData型に変換
                print("☔️jsonDataは",String(data: jsonData , encoding: .utf8)!)
        
                //このあとファイルに書き出す処理を書く。
                let dirURL = FileManager.default.currentDirectoryPath
        
                print("🌷",dirURL)
        
                guard let fileURL = URL(string:"file://" + dirURL + "/Kyoto/FoodData.json") else {
                    fatalError("fileURLエラー") }
                print(fileURL)
                do {
                    try jsonData.write(to: fileURL)
                } catch {
                    fatalError("JSON書き込みエラー")
                }
        
        
        
        
    }
    
    
    
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
    
    static func getCafeData(cafeName:String) async throws -> [Menu]{
        guard let num = cafeDict[cafeName]  else {return []}//650111とか
        let urlArray = [
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_a",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_b",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_c",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_d",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_e",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_bunrui1",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_bunrui2",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_bunrui3",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_f",
            "https://west2-univ.jp/sp/menu_load.php?t=" + num + "&a=on_g"
        ]
        
        var menusArray : [Menu] = []
        
        for url in urlArray {
            
            var foodNameArray : [String] = []
            var priceArray : [String] = []
            var foodsArray : [Food] = []
            
            
            let response = await AF.request(url, method: .get, headers: nil).serializingString().response
            guard let html = response.value, let doc = try? SwiftSoup.parse(html) else {
                print(url,"は読み込まれず。😛ここでおしまい。。。")
                // ここreturn じゃないのは次のfor文にまわってほしいから。
                continue }
            
            //画像を取得
            let srcs: Elements = try doc.select("img[src]")
            var srcsStringArray: [String] = srcs.array().map { try! $0.attr("src").description }
            //以下でvegan のマーク画像などをarrayから消去する。
            srcsStringArray.removeAll(where: {$0.contains("bigicon")})
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
                    guard let html = response.value, let doc = try? SwiftSoup.parse(html) else {return [] }
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
                    var japanese = japaneseAndEnglish?.replacingOccurrences(of:spanText!, with:"")
                    print("🤩",japanese)
                    // 「〇〇丼中」とかいう名前の「中」を消去
                    if japanese?.last == "中" {
                        let japaneseString = japanese?.dropLast() ?? ""
                        japanese = String(japaneseString)
                    }
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
                    guard let text = try? string.text() else {return []}
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
            //URLの最後の文字列を取得してattrとする(属性)
            let lastCharacter = url.last!
            print("😤",lastCharacter)
            // ここからjsonを作る。
            for i in 0 ..< foodNameArray.count {
                
                //JSON 化したいデータを 構造体 で作成
                let food = Food(name: foodNameArray[i],
                                price: priceArray[i],
                                img: srcsStringArray[i],
                                attr:"\(lastCharacter)")
                
                // ここでルネの対策を入れる。suffixに「ミニ」「小」「大」「S」「L」がつくものはデータ自体から消去
                // (ご飯のサイズ情報がルネのみ詳細画面に行かずとも含まれるため。)
                // ただしケバブプレートLも消去される。
                if (foodNameArray[i].hasSuffix("ミニ") ||
                    foodNameArray[i].hasSuffix("小") ||
                    foodNameArray[i].hasSuffix("大") ||
                    foodNameArray[i].hasSuffix("Ｓ") ||
                    foodNameArray[i].hasSuffix("Ｌ")
                ) {
                    print("データを登録しません🙅‍♀️")
                    continue
                }
                print("このデータは登録する⭕️")
                foodsArray.append(food)
            }
            
            
            
            
            //JSON 化したいデータを 構造体 で作成
            let menu = Menu(name: cafeName ,
                            foods: foodsArray)
            
            menusArray.append(menu)
        }
        
        return menusArray
        
        
    }
    
    
}



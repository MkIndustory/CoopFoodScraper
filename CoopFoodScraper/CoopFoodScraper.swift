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
    /*
     京都大学中央食堂の場合
     　主菜：on_a
     　副菜：on_b
     　麺類：on_c
     　丼・カレー：on_d
     　デザート：on_e
     　夜限定メニュー：on_bunrui2
     */
    
    struct Food: Codable {
        var name: String //ごはんの名前
        var price: String //ごはんの値段
        var img: String //imgのURL
    }
    
    static let url = URL(string: "https://west2-univ.jp/sp/menu_load.php?t=650111&a=on_c")!
    static var foodNameArray : [String] = []
    static var priceArray : [String] = []
    static var foodsArray : [Food] = []
    static func main() async throws {
        let response = await AF.request(url, method: .get, headers: nil).serializingString().response
        guard let html = response.value, let doc = try? SwiftSoup.parse(html) else {return }
                
        //h3タグを取得
        let h3 = try? doc.select("h3").array()
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
                    foodNameArray.append(arr[0])
                    priceArray.append(arr[1])
                    break // "きつねそば¥319" というtextだけ欲しいのでfor文全部回さない
                }
            }
        }
        
        let srcs: Elements = try doc.select("img[src]")
        let srcsStringArray: [String] = srcs.array().map { try! $0.attr("src").description }

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
        guard let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("フォルダURL取得エラー")
        }
        let fileURL = dirURL.appendingPathComponent("FoodMenData.json")
        
        do {
            try jsonData.write(to: fileURL)
        } catch {
            fatalError("JSON書き込みエラー")
        }
    }
}



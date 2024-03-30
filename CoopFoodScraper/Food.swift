//
//  Food.swift
//  CoopFoodScraper
//
//  Created by ぴっきー！ on 2024/02/19.
//

import Foundation

struct Food: Codable {
    var name: String //ごはんの名前
    var price: String //ごはんの値段
    var img: String //imgのURL
    var attr: String // a,b,c,d,e,1,2,3のどれかの属性
}

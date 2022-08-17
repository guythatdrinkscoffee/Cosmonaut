//
//  APOD.swift
//  Kosmo
//
//  Created by J Manuel Zaragoza on 8/16/22.
//

import Foundation

struct Item: Codable, Identifiable, Hashable{
    let id = UUID()
    let copyright: String?
    let date, explanation: String
    let hdurl: String?
    let mediaType, serviceVersion, title: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case copyright, date, explanation, hdurl
        case mediaType = "media_type"
        case serviceVersion = "service_version"
        case title, url
    }
}

extension Item {
    var imageURL: URL {
        if let url = URL(string: self.url){
            return url
        } else {
            return URL(string: "")!
        }
    }
}

extension Item {
   static func initFromJsonFile() -> [Item] {
        guard let fileUrl = Bundle.main.url(forResource: "mockdata", withExtension: "json") else { return []}
        
        do {
            let jsonData = try Data(contentsOf: fileUrl)
            let results = try JSONDecoder().decode([Item].self, from: jsonData)
            return results
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}


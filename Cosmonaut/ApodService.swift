//
//  ApodService.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import Foundation
import Combine

struct ApodService {
    private let key = "Your key goes here"
    
    private enum Endpoints {
        static let baseURL = URL(string: "https://api.nasa.gov/planetary/apod")!
    }
    
    private enum ApodServiceError: Error {
        case invalidURL
    }
    
    public func fetchInDateRange(start: String, end: String) -> AnyPublisher<[Item],Error> {
        guard var urlComponents = URLComponents(url: Endpoints.baseURL, resolvingAgainstBaseURL: false) else {
            return Fail(error: ApodServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date", value: end),
            URLQueryItem(name: "api_key", value: key),
        ]
        
        guard let url = urlComponents.url else {
            return Fail(error: ApodServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .map({ data in
                return data
            })
            .print()
            .decode(type: [Item].self, decoder: JSONDecoder())
            .map { items in
                return items.filter({$0.mediaType == "image"}).reversed()
            }
            .eraseToAnyPublisher()
    }
    
    public func fetchForDate(date: String) -> AnyPublisher<Item,Error> {
        guard var urlComponents = URLComponents(url: Endpoints.baseURL, resolvingAgainstBaseURL: false) else {
            return Fail(error: ApodServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "api_key", value: key),
        ]
        
        guard let url = urlComponents.url else {
            return Fail(error: ApodServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Item.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
    

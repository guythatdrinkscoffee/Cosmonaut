//
//  ApodService.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import Foundation
import Combine

struct ApodService {
    
    
    private enum Endpoints {
        static let baseURL = URL(string: "https://api.nasa.gov/planetary/apod")!
    }
    
    private enum ApodServiceError: Error {
        case invalidURL
    }
    
    public var isFetching: Bool = false
    
    public mutating func fetchInDateRange(start: String, end: String) -> AnyPublisher<[Item],Error> {
        guard var urlComponents = URLComponents(url: Endpoints.baseURL, resolvingAgainstBaseURL: false) else {
            return Fail(error: ApodServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date", value: end),
//            URLQueryItem(name: "api_key", value: key)
        ]
        
        guard let url = urlComponents.url else {
            return Fail(error: ApodServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Item].self, decoder: JSONDecoder())
            .map { items in
                return items.filter({$0.mediaType == "image"}).reversed()
            }
            .eraseToAnyPublisher()
    }
    
    mutating func setIsFetching(_ fetching: Bool){
        isFetching = fetching
    }
}
    

//
//  DownloadService.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/19/22.
//

import Foundation
import UIKit
import Combine

final class DownloadService {
    enum DownloadService: Error {
        case invalidURL
    }
    
    func checkHasHDPhoto(for item: Item) -> AnyPublisher<Bool,Never> {
        if let _ = item.hdurl {
            return Just(true).eraseToAnyPublisher()
        }
        return Just(false).eraseToAnyPublisher()
    }
    
    func downloadHDImage(for item: Item) -> AnyPublisher<UIImage, Error> {
        guard let hdUrlString = item.hdurl, let hdUrl = URL(string: hdUrlString) else {
            return Fail(error: DownloadService.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared
            .dataTaskPublisher(for: hdUrl)
            .mapError({ urlError in
                return DownloadService.invalidURL
            })
            .map(\.data)
            .map { imageData in
                return UIImage(data: imageData)
            }
            .replaceNil(with: UIImage(systemName: "moon.stars")!)
            .eraseToAnyPublisher()
    }
}

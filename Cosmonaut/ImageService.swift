//
//  ImageService.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import Foundation
import Combine
import UIKit

final class ImageService {
    private enum ImageServiceError: Error {
        case unknown
    }
    
    
    
    public func fetchImageForItem(_ item: Item) -> AnyPublisher<UIImage, Error> {
        let url = item.imageURL
        
        if let image = ImageStore.shared.retreive(key: NSString(string: url.absoluteString)) {
            return Future<UIImage,Error> { promise in
                promise(.success(image))
            }
            .eraseToAnyPublisher()
        } else {
            return URLSession.shared
                .dataTaskPublisher(for: url)
                .mapError({ urlError in
                    return ImageServiceError.unknown
                })
                .map(\.data)
                .map { data -> UIImage? in
                    return UIImage(data: data)
                }
                .replaceNil(with: UIImage(systemName: "moon.stars")!)
                .eraseToAnyPublisher()
        }

    }
}

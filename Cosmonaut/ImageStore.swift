//
//  ImageStore.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import Foundation
import UIKit

final class ImageStore {
    static let shared = ImageStore()
    private var cache: NSCache<NSString,NSData>
    
    init(){
        cache = NSCache<NSString,NSData>()
    }
    
    public func insert(key: NSString,image: UIImage){
        do {
            //Check that it doesnt exist in the cache
            guard retreive(key: key) == nil else { return }
        
            let data = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: true) as NSData
            cache.setObject(data, forKey: key)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func retreive(key: NSString) -> UIImage? {
        do {
            guard let data = cache.object(forKey: key) as? Data else {
                return nil
            }
            
            let image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data)
            
            return image
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

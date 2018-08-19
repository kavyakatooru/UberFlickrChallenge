//
//  Photo.swift
//  UberFlickrChallenge
//
//  Created by Kavya on 8/18/18.
//  Copyright © 2018 Level. All rights reserved.
//

import Foundation

class Photo: NSObject, Codable {
    
    var id : String?
    var owner : String?
    var server : String?
    var secret : String?
    var farm : Int?
    var title : String?
    var ispublic : Int?
    var isfriend : Int?
    var isfamily : Int?
    
    var photoUrlString: String {
        return "http://farm\(farm!).static.flickr.com/\(server!)/\(id!)_\(secret!).jpg"
    }
    
    func getFlickrPhotosUsingUrl(url : URL, responseBlock : @escaping (_ responseObject: [NSDictionary]?,_ error: NSError?) -> Void) {
        let searchTask = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error -> Void in
            if error != nil {
                print("Call failed with error: \(error!.localizedDescription)")
                responseBlock(nil, error as NSError?)
                return
            }
            do {
                let resultsDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject]
                guard let results = resultsDictionary else { return }
                
                if let statusCode = results["code"] as? Int {
                    if statusCode == 100 {
                        let invalidAccessError = NSError(domain: "com.flickr.api", code: statusCode, userInfo: nil)
                        responseBlock(nil,invalidAccessError)
                        return
                    }
                }
                guard let photosContainer = resultsDictionary!["photos"] as? NSDictionary else { return }
                guard let pagesCount = photosContainer["pages"] as? Int else { return }
                pages = pagesCount
                guard let photosArray = photosContainer["photo"] as? [NSDictionary] else { return }
                print("PhotosArray:", photosArray)
                responseBlock(photosArray, nil)
            }
            catch let error as NSError {
                print("Error parsing JSON: \(error)")
                responseBlock(nil,error)
                return
            }
        })
        searchTask.resume()
    }
    
}

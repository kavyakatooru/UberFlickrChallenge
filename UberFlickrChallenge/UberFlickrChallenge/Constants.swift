//
//  Constants.swift
//  UberFlickrChallenge
//
//  Created by Kavya on 8/18/18.
//  Copyright © 2018 Level. All rights reserved.
//

import Foundation
import UIKit

let kFlickrAPIKey : String = "3e7cc266ae2b0e0d78e279ce8e361736"
let kFlickrSearchUrl : String = "https://api.flickr.com/services/rest/"

var pages : Int?
extension UIViewController {
    func addQueryParams(url: URL, newParams: [URLQueryItem]) -> URL? {
        let urlComponents = NSURLComponents.init(url: url, resolvingAgainstBaseURL: false)
        guard urlComponents != nil else { return nil; }
        if (urlComponents?.queryItems == nil) {
            urlComponents!.queryItems = [];
        }
        urlComponents!.queryItems!.append(contentsOf: newParams);
        return urlComponents?.url;
    }
}

extension UIImageView{
    
    func setImageFromURl(stringImageUrl url: String){
        DispatchQueue.global(qos: .background).async {
            if let url = NSURL(string: url) {
                if let data = NSData(contentsOf: url as URL) {
                    DispatchQueue.main.async(execute: {
                        self.image = UIImage(data: data as Data)
                    })
                }
            }
        }
        
    }
    
}



//
//  HomeViewController.swift
//  UberFlickrChallenge
//
//  Created by Kavya on 8/18/18.
//  Copyright © 2018 Level. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIScrollViewDelegate,UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var photoCollectionViewCell: UICollectionView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var photoObj : Photo?
    var photoObjArray : [NSDictionary]?
    var photoObjSearchArray : [NSDictionary]?
    let imageCache = NSCache<NSString, UIImage>()
    var page : Int?
    var searchViewOn : Bool?
    var isAPIRunning: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Flickr Photos"
        self.searchBar.delegate = self
        self.photoObj = Photo()
        self.page = 1
        self.searchViewOn = false
        self.isAPIRunning = false
        self.photoObjArray = [NSDictionary]()
        self.photoObjSearchArray = [NSDictionary]()

        self.getFlickerPhotos(searchText: "", pageNumber: self.page!)
        self.photoCollectionViewCell.register(UINib.init(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoCollectionViewCell")
        
        let flowLayout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        let width = (self.photoCollectionView.frame.size.width - 40) / 3 ;
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .vertical
        self.photoCollectionView.setCollectionViewLayout(flowLayout, animated: true)
        self.photoCollectionView.alwaysBounceVertical = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFlickerPhotos(searchText : String, pageNumber : Int) {
        var encodedSearchText = searchText.addingPercentEncoding(withAllowedCharacters:.urlFragmentAllowed)!
        var urlString = ""
        if encodedSearchText == "" {
            encodedSearchText = "%22%22"
        }
        urlString = "\(kFlickrSearchUrl)?method=flickr.photos.search&api_key=\(kFlickrAPIKey)&page=\(pageNumber)&format=json&nojsoncallback=1&safe_search=1&text=\(encodedSearchText)"
        let Url: URL = URL(string: urlString)!
        print("Url is :",Url )
        self.photoObj?.getFlickrPhotosUsingUrl(url: Url, responseBlock: { (responseObject : [NSDictionary]?, error : NSError?) in
            if error == nil {
                self.isAPIRunning = false
                if self.searchViewOn! {
                    self.photoObjSearchArray?.append(contentsOf: responseObject! )
                }else{
                    self.photoObjArray?.append(contentsOf: responseObject!)

                }
                DispatchQueue.main.async {
                    self.photoCollectionView.reloadData()
                }
            }else{
                print("API error=\(error!.localizedDescription)")
            }
        })
    }
    
    
    func downloadImage(url: URL, completion: @escaping (_ image: UIImage?, _ error: Error? ) -> Void){
        if let cachedImage = self.imageCache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage, nil)
        } else {
            DispatchQueue.global(qos: .background).async {
                if let data = NSData(contentsOf: url) {
                    DispatchQueue.main.async(execute: {
                        let downloadedImage : UIImage = UIImage(data: data as Data)!
                        self.imageCache.setObject(downloadedImage, forKey: url.absoluteString as NSString)
                        completion(downloadedImage, nil)
                    })
                }
            }
        }
    }
    
    
    //MARK:CollectionView Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.searchViewOn! {
            return (self.photoObjSearchArray?.count)!
        }
        return (self.photoObjArray?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "photoCollectionViewCell"
        
        var cell : PhotoCollectionViewCell! = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        if cell == nil {
            
            collectionView.register(UINib(nibName : "PhotoCollectionViewCell", bundle :nil), forCellWithReuseIdentifier: cellIdentifier)
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCollectionViewCell
        }
        var arrayObj = NSDictionary()
        if self.searchViewOn!{
            arrayObj = self.photoObjSearchArray![indexPath.row]
        }else{
            arrayObj = self.photoObjArray![indexPath.row]
        }
//        let arrayObj = self.photoObjArray![indexPath.row]
        do {
            let data = try JSONSerialization.data(withJSONObject: arrayObj, options: .prettyPrinted)
            let decoder = JSONDecoder()
            self.photoObj = try decoder.decode(Photo.self, from: data)
            self.downloadImage(url: URL(string: self.photoObj!.photoUrlString)!,completion : {(image : UIImage?, error : Error?) in
                if error == nil {
                    cell.photoImageView.image = image
                }
            })
        } catch let error as NSError  {
            print("Handle error", error.localizedDescription)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.size.width - 40) / 3;
        return CGSize(width: width, height: width)
        
    }
    
    //MARK:ScrollView Methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : Float = Float(offset.y + bounds.size.height - inset.bottom)
        let h : Float = Float(size.height)
        
        let reload_distance : Float = 10
        
        if (y > h + reload_distance) {
            if !self.searchViewOn! {
                if(!self.isAPIRunning! && self.photoObjArray?.count != 0 && pages != self.page && pages != 0){
                    self.page = self.page! + 1
                    self.isAPIRunning = true
                    self.getFlickerPhotos(searchText: "", pageNumber: self.page!)
                }
            }else{
                if(!self.isAPIRunning! && self.photoObjSearchArray?.count != 0 && pages != self.page && pages != 0){
                    self.page = self.page! + 1
                    self.isAPIRunning = true
                    self.getFlickerPhotos(searchText: self.searchBar.text!, pageNumber: self.page!)
                }
            }
        }
        
    }
    
    //MARK:SearchBar Methods
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.searchViewOn = true
        let searchStr = searchBar.text
        self.photoObjSearchArray?.removeAll()
        self.page = 1
        self.getFlickerPhotos(searchText: searchStr!, pageNumber: self.page!)
        print("search Clicked")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.photoObjArray?.removeAll()
        self.searchViewOn = false
        self.page = 1
        self.getFlickerPhotos(searchText: "", pageNumber: self.page!)
    }
}



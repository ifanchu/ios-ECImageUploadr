//
//  ViewController.swift
//  ECImageUploadr
//
//  Created by ifanchu on 10/12/18.
//  Copyright © 2018 ifanchu. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire


class ViewController: UIViewController {

   @IBOutlet weak var progressView: UIProgressView!
   @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view, typically from a nib.
      
      self.progressView.progress = 0.0
      self.progressView.isHidden = true
      self.activityIndicatorView.stopAnimating()
   }

   @IBAction func presentImageUploadr1(_ sender: Any) {
      let vc = ECImageUploadrViewController<ImageUploadrRequest>()
      self.progressView.setProgress(0.0, animated: true)
      self.progressView.isHidden = false
      vc.request = ImageUploadrRequest()
      vc.preUploadBlock = {
         self.activityIndicatorView.startAnimating()
      }
      vc.successCompletion = { response in
         self.activityIndicatorView.stopAnimating()
         if let url: URL = response?.imageUrl {
            let alert = UIAlertController(
               title: "Success",
               message: "URL: \(url.absoluteString)",
               preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
         }
      }
      vc.progressCompletion = { progress in
         self.progressView.setProgress(progress, animated: true)
         print("Upload progress: \(progress)")
      }
      vc.failureCompletion = { error in
         self.activityIndicatorView.stopAnimating()
         let alert = UIAlertController(
            title: "Failed",
            message: "\(error)",
            preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
         self.present(alert, animated: true, completion: nil)
      }
      vc.cancelCompletion = {
         let alert = UIAlertController(
            title: "Cancelled",
            message: nil,
            preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
         self.present(alert, animated: true, completion: nil)
      }
      self.present(vc, animated: true) {
         self.activityIndicatorView.stopAnimating()
      }
   }
   
}


//=====================  Implementation  =============================

struct ImageUploadrResponse: ECImageUploadrResponseProtocol {
   var imageUrl: URL?
   
   init(receivedJson: JSON?) {
      guard let receivedJson = receivedJson else { return }
      self.imageUrl = URL(string: receivedJson["photo"].stringValue)
   }
   
}

struct ImageUploadrRequest: ECImageUploadrRequestProtocol {
   
   typealias Response = ImageUploadrResponse
   
   init() {}
   
   var endpoint: String = "http://localhost:8000/api/v1/players/upload_avatar"
   
   var queryParams: [String : Any]? = ["requester_id":"58sz3vTB9dhC4o7m34qFHH"]
   
   var headers: HTTPHeaders? = nil
   
}

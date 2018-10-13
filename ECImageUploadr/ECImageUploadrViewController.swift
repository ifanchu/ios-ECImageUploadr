//
//  Alamofire.swift
//
//  Copyright (c) 2018 Evan Chu ()
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Alamofire
import SwiftyJSON


public protocol ECImageUploadrResponseProtocol {
   /**
    After sending request to REST endpoint, it will return JSON response.
    To use it, have a struct extends this protocol and define instance variables
    to be parsed and constructed out of receivedJson
    */
   init(receivedJson: JSON?)
}


public protocol ECImageUploadrRequestProtocol{
   associatedtype Response: ECImageUploadrResponseProtocol
   
   /// The endpoint to upload the image
   var endpoint: String { get }
   
   /// url query params, eg. https://{endpoint}/api/v1/xxx?q1=v1
   var queryParams: [String:Any]? { get }
   
   var headers: HTTPHeaders? { get }
}


public enum ECImageUploadrRequestResult<T: ECImageUploadrRequestProtocol> {
   /**
    Represents succesful result of a `ECImageUploadrRequestProtocol`.
    Encapsulates ECImageUploadrResponseProtocol from the server.
    */
   case success(response: T.Response)
   /**
    Represents errored result of a `ECImageUploadrRequestProtocol`.
    Encapsulates error that was encountered.
    */
   case failed(error: String)
}


/// This class is to provide the functionality of choose/capure an image and then upload
/// it to a server using a REST endpoint with Alamofire and then returns a ECImageUploadrResponseProtocol.
/// The caller constructs this controller and provide both request and onDoneBlock and then present it.
/// The onDoneBlock will be executed when this VC got dismissed.
class ECImageUploadrViewController<T: ECImageUploadrRequestProtocol>:UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
   var request: T?
   
   /// This block will be executed when this VC got dismissed after the
   /// image is uploaded successfully
   var successCompletion: ((T.Response?) -> Void)?
   /// This block will be executed if the image failed to upload
   var failureCompletion: ((String) -> Void)?
   /// This block will be executed before uploading
   var preUploadBlock: (() -> Void)?
   /// This block will be executed every time a new progress is reported
   var progressCompletion: ((Float) -> Void)?
   /// This block will be executed when the picker view was canceled
   var cancelCompletion: (() -> Void)?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      //      self.view.backgroundColor = .clear
      self.delegate = self
      self.allowsEditing = true
      
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
         self.sourceType = .camera
      } else {
         self.sourceType = .photoLibrary
         self.modalPresentationStyle = .fullScreen
      }
      self.navigationController?.navigationBar.tintColor = .black
      
   }
   
   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
         print("Info did not have the required UIImage for the Original Image")
         dismiss(animated: true)
         return
      }
      
      self.upload(image: image)
      self.dismiss(animated: true, completion: nil)
   }
   
   func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      self.dismiss(animated: true) {
         if let block = self.cancelCompletion {
            block()
         }
      }
   }
   
}

extension ECImageUploadrViewController {
   
   func upload(image: UIImage) {
      guard let imageData = image.jpegData(compressionQuality: 0.5) else {
         print("Could not get JPEG representation of UIImage!")
         return
      }
      
      guard let request = self.request else {
         print("Request not set!")
         return
      }
      
      let queryParams: [String:Any]!
      if let qp = request.queryParams {
         queryParams = qp
      }else{
         queryParams = [:]
      }
      
      // add default header
      let headers: [String:String]!
      if let h = request.headers {
         headers = h
      }else{
         headers = [:]
      }
      
      // construct url with queryParams
      var url = request.endpoint
      var querystrings:[String] = []
      for (key, value) in queryParams {
         querystrings.append("\(key)=\(value)")
      }
      if querystrings.count > 0 {
         url = "\(url)?\(querystrings.joined(separator: "&"))"
      }
      
      url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      
      if let block = self.preUploadBlock {
         block()
      }
      
      Alamofire.upload(
         multipartFormData: { multiPartFormData in
            multiPartFormData.append(imageData, withName: "imagefile", fileName: "image.jpeg", mimeType: "image/jpeg")
      },
         usingThreshold: 10,
         to: url,
         method: .post,
         headers: headers) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
               upload.uploadProgress { progress in
                  if let block = self.progressCompletion {
                     block(Float(progress.fractionCompleted))
                  }
               }
               upload.validate()
               upload.responseJSON { response in
                  guard response.result.isSuccess, let value = response.result.value else {
                     print("Error while uploading file: \(String(describing: response.result.error))")
                     if let block = self.failureCompletion {
                        block(response.result.error?.localizedDescription ?? "")
                     }
                     return
                  }
                  let data = JSON(value)
                  let ret = T.Response.init(receivedJson: data)
                  if let block = self.successCompletion {
                     block(ret)
                  }
               }
            case .failure(let encodingError):
               if let block = self.failureCompletion {
                  block(encodingError.localizedDescription)
               }
            }
      }
   }
   
}

# ios-ECImageUploadr
A quick image upload view controller. ECImageUploadr is a subclass of UIImagePickerViewController
with several convenient closures. 

## Install

Simply copy ECImageUploadrViewController.swift to your project. 
And add `Alamofire` and `SwiftJSON` to your Podfile.

## Usage

Please refer to `ViewController.swift` in this repo. 

1. First you need to implement a Response object that conforms to `ECImageUploadrResponseProtocol`, here you
need to define how to parse the json returned by the endpoint. 

2. Then you need to implement a Request object that conforms to `ECImageUploadrRequestProtocol`, here you 
need to define the endpoint to upload the image and any needed query params or headers. 

3. Then you simply construct the view controller and provide the Request class
```
let vc = ECImageUploadrViewController<ImageUploadrRequest>()
``` 

Then construct the Request object and provide it to the view controller

```
vc.request = ImageUploadrRequest()
```

After this you can configure those closure as needed. The first one is the success completion closue which 
will give you the Response object you defined earlier

```
vc.successCompletion = { response in
}
```

Progress completion closure will provide the progress as a Float during upload

```
vc.progressCompletion = { progress in
   print("Upload progress: \(progress)")
}
```

Failure completion closure will provide the error message, if any.

```
vc.failureCompletion = { error in
}
```

Cancel completion closure will be called if the picker view was cancelled

```
vc.cancelCompletion = {
}
```

After all these configurations, simply present it

```
self.present(vc, animated: true) {
}
```

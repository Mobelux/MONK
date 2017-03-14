# MONK
Mobelux Network Kit, a simple networking library based on URLSession in Swift. URLSession (formally NSURLSession) is pretty nice, however it leaves a good amount of work that needs to be done to do common things. MONK is meant to be a fairly simple wrapper around URLSession that resolves many of these pain points. 

# Usage

## Basics
To start you will want to make an instance of the `NetworkController` class. You can start out with passing no parameters on `init`, however if you wish to customize the session, you can pass in a `URLSessionConfiguration`. 

You will want to retain a refrence to this controller until you are finished with all networking.

## Downloding Data

Now that you have a `NetworkController` initalized, you can do basic requests.

```
let url: URL = <some url>
let request = DataRequest(url: url, httpMethod: .get)
let task = networkController.data(with: request)
// Optional
task.addProgress { (progress) in
	print("\(progress.totalBytes), \(progress.completeBytes), \(progress.progress)")
}
// End optional

// you can add multiple progress or completion handlers
task.addCompletion { (result) in
	switch result {
	case .success(let statusCode, let responseData):
		// do stuff
	case .failure(let error):
	   // cry
}

task.resume()
```
Under the hood for `.get` or `.delete` requests MONK will use a `URLSessionDataTask`

## Uploading Data
Uploading data is nearly identical to a [basic download](#downloading-data). With `POST`, `PUT`, and `PATCH` requests you can specifiy an optional `UploadableData`, that can be JSON, `Data`, or files that are treated as multipart uploads. In addition to the optional `addProgress()` handler for getting download progress updates, you can also register upload progress handlers via `addUploadProgress()`. If you do a `POST`, `PUT`, or `PATCH` and have a non-nil `bodyData` then MONK will use a `URLSessionUploadTask`, otherwise it will behave like [basic download](#downloading-data) and use a `URLSessionDataTask`.

```
let url: URL = <some url>
let json: JSON = <some json>
let bodyData = UploadableData.json(json: json)
let request = DataRequest(url: url, httpMethod: .post(bodyData: bodyData))

// the rest is just like a download request

// Optional
task.addUploadProgress { (progress) in 
	print("\(progress.totalBytes), \(progress.completeBytes), \(progress.progress)")
}

...
```
## Downloading Files
Downloading files is nearly identical to [basic download](#downloading-data), the only difference is you use a `DownloadRequest` instead of a `DataRequest`. You specify a URL where MONK should place your downloaded file once the download is complete. Unlike `URLSession` you do NOT have to move the file from this location before using it.

```
let localURL: URL = <url where you want the file downloaded to>
let request = DownloadRequest(url: url, httpMethod: .get, localURL: localURL)
```

## Network activity indicator

Controlling iOS' network activity indicator is something that MONK does not do directly. There are multiple reasons why, but the most important is that MONK only uses App extension safe API. Controlling the network activity indicator requires a refrence to the `UIApplication` instance, which isn't available to an extension.

You will want to make sure you initialized your `NetworkController` with an object conforming to the `NetworkControllerDelegate` protocol. In your object you can listen to calls of `func networkController(networkController: NetworkController, didChangeNumberOfActiveTasksTo numberOfActiveTasks: Int)` and show the network activity indicator when `numberOfActiveTasks > 0`, and hide it when `numberOfActiveTasks == 0`. If you have multiple `NetworkController` instances then its a lot more complex, and that is up to you to figure out ;)

## Certificate Pinning
When initalizing a `NetworkController` there is a `serverTrustSettings: ServerTrustSettings?` parameter. If you want to do certificate, or public key pinning you will want to create a `ServerTrustSettings` and pass it in here.

Example:

```
let mobeluxCertFile: URL = <cert file that you shipped inside your app bundle>
let policies = ["https://mobelux.com" : .pinCertificates(certificates: [.file(url: mobeluxCertFile)])]
let trustSettings = ServerTrustSettings(policies: policies)
let networkController = NetworkController(serverTrustSettings: trustSettings)

```

## Request specific headers & settings
When you initialize a `Data/DownloadRequest` there is a `settings: RequestSettings?` paramater that you can use to setup more complex requests.

You can specify the type of traffic for this request, a cache policy, if cellular radios can be used, and add additional headers above the ones added for all requests on this `NetworkController`.


# Installation

The preferred way to integrate this in your project is to add it as a submodule to your repo, then you can just add it's Xcode project to your app.

Cocoapods is also supported
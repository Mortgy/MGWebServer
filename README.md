
# MGWebServer

MGWebServer is a lightweight, cross-platform HTTP server framework for iOS, iPadOS, and macOS. It supports Bonjour service discovery, background task management, and audio playback to keep the server alive on iOS and iPadOS.

## Features

- Cross-platform support for iOS, iPadOS, and macOS
- Bonjour service discovery
- Background task management
- Audio playback to keep the server alive on iOS and iPadOS
- Easily add routes to handle HTTP requests
- Static file serving

## Installation

### Swift Package Manager

To integrate MGWebServer into your project using Swift Package Manager, add the following dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mortgy/MGWebServer.git", from: "1.0.0")
]
```

Then, in your target, add `MGWebServer` as a dependency:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: ["MGWebServer"]
    )
]
```

## Usage

### Setting up the Server

1. **AppDelegate for iOS/iPadOS**

```swift
import UIKit
import MGWebServer

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webServer: MGWebServer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let configuration = MGWebServerConfiguration(port: 8080, enableKeepAlive: true, enableBonjour: true)
        webServer = MGWebServer(configuration: configuration)
        
        webServer?.addRoute(path: "/hello") { request in
            return HTTPResponse(statusCode: 200, headers: ["Content-Type": "text/plain"], body: "Hello, world!".data(using: .utf8))
        }
        
        webServer?.start()
        
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        webServer?.stop()
    }
}
```

2. **AppDelegate for macOS**

```swift
import Cocoa
import MGWebServer

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var webServer: MGWebServer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let configuration = MGWebServerConfiguration(port: 8080, enableKeepAlive: true, enableBonjour: true)
        webServer = MGWebServer(configuration: configuration)
        
        webServer?.addRoute(path: "/hello") { request in
            return HTTPResponse(statusCode: 200, headers: ["Content-Type": "text/plain"], body: "Hello, world!".data(using: .utf8))
        }
        
        webServer?.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        webServer?.stop()
    }
}
```

### Enabling Bonjour Service

To enable Bonjour service in your project, you need to add the following settings to your project's `Info.plist` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
    <string>_mg-http._tcp</string>
</array>
</plist>
```

### Discovering Services using Bonjour

1. **ViewController for iOS/iPadOS/macOS**

```swift
import UIKit
import MGWebServer

class ViewController: UIViewController {
    private let bonjourClientManager = BonjourClientManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Start browsing for services
        bonjourClientManager.startBrowsing { services in
            for service in services {
                print("Discovered service: \(service.name), URL: \(service.url), IP: \(service.ipAddress), Device Type: \(service.deviceType)")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop browsing for services when the view disappears
        bonjourClientManager.stopBrowsing()
    }
}
```

## Components

### MGWebServer

The core server class that manages the HTTP server, routes, background tasks, and Bonjour services.

### MGWebServerConfiguration

Configuration class for initializing `MGWebServer` with various options.

### BonjourServiceManager

Manages publishing the server's URL and port over Bonjour.

### BonjourClientManager

Manages discovering Bonjour services on the local network.

### BackgroundTaskManager

Handles background task management to keep the server alive on iOS and iPadOS.

### AudioPlaybackManager

Handles audio playback to keep the server alive on iOS and iPadOS.

### HTTPRequest and HTTPResponse

Classes for managing HTTP requests and responses.

## Requirements

- iOS 12.0+ / macOS 10.14+ / visionOS 1.0+
- Xcode 11+
- Swift 5.1+

## License

MGWebServer is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

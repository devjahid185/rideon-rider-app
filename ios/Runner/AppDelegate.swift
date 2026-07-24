import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import WebKit
import AVFoundation
import CoreLocation  // ✅ Import CoreLocation for location services

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?  // ✅ Location Manager instance

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Initialize Google Maps
        GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: self)
        
        // Configure WebView for WebRTC (Camera & Microphone)
        configureWebViewPermissions()
        
        // Setup Flutter MethodChannel for permissions
        setupPermissionChannel()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ✅ Configure WebView to allow camera/microphone access
    private func configureWebViewPermissions() {
        if #available(iOS 14, *) {
            let webViewConfiguration = WKWebViewConfiguration()
            webViewConfiguration.allowsInlineMediaPlayback = true
            webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        }
    }

    // ✅ Setup Flutter MethodChannel for requesting permissions
    private func setupPermissionChannel() {
        let controller = window?.rootViewController as! FlutterViewController
        let permissionChannel = FlutterMethodChannel(name: "permissions", binaryMessenger: controller.binaryMessenger)

        permissionChannel.setMethodCallHandler { (call, result) in
            DispatchQueue.global(qos: .userInitiated).async {
                if call.method == "requestCameraPermission" {
                    self.requestCameraPermission(result: result)
                } else if call.method == "requestMicrophonePermission" {
                    self.requestMicrophonePermission(result: result)
                } else if call.method == "requestLocationPermission" {  // ✅ New: Location permission
                    self.requestLocationPermission(result: result)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }

    // ✅ Request Camera Permission
    private func requestCameraPermission(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                result(granted)
            }
        }
    }

    // ✅ Request Microphone Permission
    private func requestMicrophonePermission(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                result(granted)
            }
        }
    }

    // ✅ Request Location Permission
    private func requestLocationPermission(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            self.locationManager?.requestWhenInUseAuthorization()  // Request location permission
            self.locationManager?.startUpdatingLocation()
            result(true)
        }
    }

    // ✅ Handle location authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location access granted")
        case .denied, .restricted:
            print("❌ Location access denied")
        case .notDetermined:
            print("🔄 Waiting for user decision")
        @unknown default:
            print("⚠️ Unknown location authorization status")
        }
    }
}


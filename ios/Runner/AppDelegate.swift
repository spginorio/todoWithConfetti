import Flutter
import UIKit
// import awesome_notifications
// import shared_preferences_ios

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//       GeneratedPluginRegistrant.register(with: self)

//       // This function registers the desired plugins to be used within a notification background action
//       SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in          
//           SwiftAwesomeNotificationsPlugin.register(
//             with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)          
//           FLTSharedPreferencesPlugin.register(
//             with: registry.registrar(forPlugin: "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin")!)
//       }

//       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }



import Flutter
import UIKit

public class DotLottieFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("🔴 DotLottie iOS: Plugin attached to engine")
        let factory = DotLottieFlutterFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "dotlottie_view")
        print("🔴 DotLottie iOS: ✅ View factory registered with ID: dotlottie_view")
    }
}
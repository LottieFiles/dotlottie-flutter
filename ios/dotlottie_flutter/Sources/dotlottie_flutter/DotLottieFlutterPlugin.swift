import Flutter
import UIKit

public class DotLottieFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = DotLottieFlutterFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "dotlottie_view")
    }
}
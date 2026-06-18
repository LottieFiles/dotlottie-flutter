import FlutterMacOS
import AppKit
import DotLottie

class DotLottieFlutterFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    // Strong references to platform views
    private var platformViews: [Int64: DotLottieFlutterPlatformView] = [:]
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withViewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> NSView {
        let platformView = DotLottieFlutterPlatformView(
            frame: CGRect.zero,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
        
        platformViews[viewId] = platformView
        
        return platformView.view()
    }
    
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    // Clean up when view is disposed
    func disposePlatformView(viewId: Int64) {
        platformViews.removeValue(forKey: viewId)
    }
}
import Flutter
import UIKit
import DotLottie

class DotLottieFlutterPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var dotLottieAnimation: DotLottieAnimation?
    private var methodChannel: FlutterMethodChannel
    private var displayLink: CADisplayLink?
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        _view.backgroundColor = .clear
        
        // Match Android: "dotlottie_view_$viewId"
        methodChannel = FlutterMethodChannel(
            name: "dotlottie_view_\(viewId)",
            binaryMessenger: messenger
        )
        
        super.init()
        
        print("🔴 DotLottie iOS: Creating platform view with id: \(viewId)")
        
        // Parse creation arguments
        if let arguments = args as? [String: Any] {
            setupAnimation(with: arguments)
        }
        
        // Set up method call handler for control methods
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }
    }
    
    func view() -> UIView {
        return _view
    }
    
    private func setupAnimation(with arguments: [String: Any]) {
        // Parse parameters matching Android
        let sourceType = arguments["sourceType"] as? String
        let source = arguments["source"] as? String
        let autoplay = arguments["autoplay"] as? Bool ?? true
        let loop = arguments["loop"] as? Bool ?? true
        let speed = arguments["speed"] as? Double ?? 1.0
        let useFrameInterpolation = arguments["useFrameInterpolation"] as? Bool ?? false
        let width = arguments["width"] as? Int
        let height = arguments["height"] as? Int
        let backgroundColor = arguments["backgroundColor"] as? String
        
        print("🔴 DotLottie iOS: Source: \(source ?? "nil"), Type: \(sourceType ?? "nil")")
        
        guard let sourceType = sourceType, let source = source else {
            print("🔴 DotLottie iOS: Missing source or sourceType")
            return
        }
        
        var config = AnimationConfig(
            autoplay: autoplay,
            loop: loop,
            speed: Float(speed),
            useFrameInterpolation: useFrameInterpolation
        )
        
        // Set optional width and height
        if let w = width {
            config.width = w
        }
        if let h = height {
            config.height = h
        }
        
        // Set background color if provided
        if let bgColor = backgroundColor, let color = parseColor(bgColor) {
            _view.backgroundColor = color
        }
        
        // Load animation based on source type (matching Android)
        switch sourceType {
        case "url":
            print("🔴 DotLottie iOS: Creating URL source for: \(source)")
            dotLottieAnimation = DotLottieAnimation(webURL: source, config: config)
            
        case "asset":
            print("🔴 DotLottie iOS: Creating asset source for: \(source)")
            dotLottieAnimation = DotLottieAnimation(fileName: source, config: config)
            
        case "json":
            print("🔴 DotLottie iOS: Creating JSON source")
            dotLottieAnimation = DotLottieAnimation(animationData: source, config: config)
            
        default:
            print("🔴 DotLottie iOS: Invalid source type: \(sourceType)")
            return
        }
        
        if let animation = dotLottieAnimation {
            print("🔴 DotLottie iOS: Animation created, setting up display link")
            setupDisplayLink(animation: animation)
            
            // Send onLoad event after animation is set up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                print("🔴 DotLottie iOS: ✅✅✅ Sending onLoad event")
                self?.methodChannel.invokeMethod("onLoad", arguments: nil)
            }
        }
    }
    
    private func setupDisplayLink(animation: DotLottieAnimation) {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = animation.framerate
        displayLink?.add(to: .main, forMode: .common)
        print("🔴 DotLottie iOS: Display link created with framerate: \(animation.framerate)")
    }
    
    @objc private func updateFrame() {
        guard let animation = dotLottieAnimation else { return }
        
        if let image = animation.tick() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let imageView = UIImageView(image: UIImage(cgImage: image))
                imageView.frame = self._view.bounds
                imageView.contentMode = .scaleAspectFit
                
                // Remove old subviews and add new frame
                self._view.subviews.forEach { $0.removeFromSuperview() }
                self._view.addSubview(imageView)
            }
        }
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let animation = dotLottieAnimation else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Animation not initialized", details: nil))
            return
        }
        
        print("🔴 DotLottie iOS: Method called: \(call.method)")
        
        switch call.method {
        case "play":
            animation.play()
            print("🔴 DotLottie iOS: ✅ Playing animation")
            methodChannel.invokeMethod("onPlay", arguments: nil)
            result(nil)
            
        case "pause":
            animation.pause()
            print("🔴 DotLottie iOS: ✅ Pausing animation")
            methodChannel.invokeMethod("onPause", arguments: nil)
            result(nil)
            
        case "stop":
            animation.stop()
            print("🔴 DotLottie iOS: ✅ Stopping animation")
            methodChannel.invokeMethod("onStop", arguments: nil)
            result(nil)
            
        case "setFrame":
            if let args = call.arguments as? [String: Any],
               let frame = args["frame"] as? Double {
                let success = animation.setFrame(frame: Float(frame))
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid frame argument", details: nil))
            }
            
        case "setProgress":
            if let args = call.arguments as? [String: Any],
               let progress = args["progress"] as? Double {
                let success = animation.setProgress(progress: Float(progress))
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid progress argument", details: nil))
            }
            
        case "setSpeed":
            if let args = call.arguments as? [String: Any],
               let speed = args["speed"] as? Double {
                animation.setSpeed(speed: Float(speed))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid speed argument", details: nil))
            }
            
        case "setLoop":
            if let args = call.arguments as? [String: Any],
               let loop = args["loop"] as? Bool {
                animation.setLoop(loop: loop)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid loop argument", details: nil))
            }
            
        case "setSegments":
            if let args = call.arguments as? [String: Any],
               let start = args["start"] as? Double,
               let end = args["end"] as? Double {
                animation.setSegments(segments: (Float(start), Float(end)))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid segments arguments", details: nil))
            }
            
        case "setMode":
            if let args = call.arguments as? [String: Any],
               let modeString = args["mode"] as? String {
                let mode: Mode
                switch modeString {
                case "forward":
                    mode = .forward
                case "reverse":
                    mode = .reverse
                case "bounce":
                    mode = .bounce
                case "reverseBounce":
                    mode = .reverseBounce
                default:
                    mode = .forward
                }
                animation.setMode(mode: mode)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid mode argument", details: nil))
            }
            
        case "isPlaying":
            result(animation.isPlaying())
            
        case "isPaused":
            result(animation.isPaused())
            
        case "isStopped":
            result(animation.isStopped())
            
        case "isLoaded":
            result(animation.isLoaded())
            
        case "totalFrames":
            result(Double(animation.totalFrames()))
            
        case "currentFrame":
            result(Double(animation.currentFrame()))
            
        case "duration":
            result(Double(animation.duration()))
            
        case "loopCount":
            result(animation.loopCount())
            
        case "speed":
            result(Double(animation.speed()))
            
        case "setTheme":
            if let args = call.arguments as? [String: Any],
               let themeId = args["themeId"] as? String {
                let success = animation.setTheme(themeId)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid theme argument", details: nil))
            }
            
        case "resize":
            if let args = call.arguments as? [String: Any],
               let width = args["width"] as? Int,
               let height = args["height"] as? Int {
                animation.resize(width: width, height: height)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid resize arguments", details: nil))
            }
            
        case "dispose":
            dispose()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func parseColor(_ colorString: String) -> UIColor? {
        var hexString = colorString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let length = hexString.count
        let r, g, b, a: CGFloat
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            a = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            r = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    private func dispose() {
        print("🔴 DotLottie iOS: Disposing view")
        displayLink?.invalidate()
        displayLink = nil
        dotLottieAnimation = nil
        _view.subviews.forEach { $0.removeFromSuperview() }
    }
    
    deinit {
        dispose()
    }
}
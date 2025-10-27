import FlutterMacOS
import AppKit
import DotLottie
import SwiftUI

class DotLottieFlutterPlatformView: NSObject {
    private var _view: NSView
    private var dotLottieAnimation: DotLottieAnimation?
    private var hostingView: NSHostingView<DotLottieView>?
    private var methodChannel: FlutterMethodChannel
    private var isDisposed = false
    private var viewId: Int64
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.viewId = viewId
        _view = NSView(frame: frame)
        _view.wantsLayer = true
        _view.layer?.backgroundColor = NSColor.clear.cgColor
        
        methodChannel = FlutterMethodChannel(
            name: "dotlottie_view_\(viewId)",
            binaryMessenger: messenger
        )
        
        super.init()
        
        print("🔴 DotLottie MacOS: Creating platform view with id: \(viewId)")
        
        if let arguments = args as? [String: Any] {
            setupAnimation(with: arguments)
        }
        
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }
    }
    
    func view() -> NSView {
        return _view
    }
    
    private func setupAnimation(with arguments: [String: Any]) {
        let sourceType = arguments["sourceType"] as? String
        let source = arguments["source"] as? String
        let autoplay = arguments["autoplay"] as? Bool ?? true
        let loop = arguments["loop"] as? Bool ?? true
        let speed = arguments["speed"] as? Double ?? 1.0
        let useFrameInterpolation = arguments["useFrameInterpolation"] as? Bool ?? false
        let width = arguments["width"] as? Int
        let height = arguments["height"] as? Int
        let backgroundColor = arguments["backgroundColor"] as? String
        
        print("🔴 DotLottie MacOS: Source: \(source ?? "nil"), Type: \(sourceType ?? "nil")")
        
        guard let sourceType = sourceType, let source = source else {
            print("🔴 DotLottie MacOS: Missing source or sourceType")
            return
        }
        
        var config = AnimationConfig(
            autoplay: autoplay,
            loop: loop,
            speed: Float(speed),
            useFrameInterpolation: useFrameInterpolation
        )
        
        if let w = width {
            config.width = w
        }
        if let h = height {
            config.height = h
        }
        
        if let bgColor = backgroundColor, let color = parseColor(bgColor) {
            _view.layer?.backgroundColor = color.cgColor
        }
        
        // Create DotLottieAnimation based on source type
        switch sourceType {
        case "url":
            print("🔴 DotLottie MacOS: Creating URL source for: \(source)")
            dotLottieAnimation = DotLottieAnimation(webURL: source, config: config)
            
        case "asset":
            print("🔴 DotLottie MacOS: Creating asset source for: \(source)")
            dotLottieAnimation = DotLottieAnimation(fileName: source, config: config)
            
        case "json":
            print("🔴 DotLottie MacOS: Creating JSON source")
            dotLottieAnimation = DotLottieAnimation(animationData: source, config: config)
            
        default:
            print("🔴 DotLottie MacOS: Invalid source type: \(sourceType)")
            return
        }
        
        guard let animation = dotLottieAnimation else {
            print("🔴 DotLottie MacOS: Failed to create animation")
            return
        }
        
        print("🔴 DotLottie MacOS: Animation created, setting up view")
        
        // Get the SwiftUI view from the animation
        let animationView = animation.view()
        
        // Wrap in NSHostingView to use in AppKit
        let hosting = NSHostingView(rootView: animationView)
        hosting.frame = _view.bounds
        hosting.autoresizingMask = [.width, .height]
        _view.addSubview(hosting)
        hostingView = hosting
        
        print("🔴 DotLottie MacOS: View added to container")
        
        // Send onLoad event
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, !self.isDisposed else { return }
            print("🔴 DotLottie MacOS: ✅✅✅ Sending onLoad event")
            self.methodChannel.invokeMethod("onLoad", arguments: nil)
        }
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard !isDisposed else {
            result(FlutterError(code: "DISPOSED", message: "View has been disposed", details: nil))
            return
        }
        
        guard let animation = dotLottieAnimation else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Animation not initialized", details: nil))
            return
        }
        
        print("🔴 DotLottie MacOS: Method called: \(call.method)")
        
        switch call.method {
            // Playback control methods
        case "play":
            let success = animation.play()
            print("🔴 DotLottie MacOS: ✅ Playing animation")
            methodChannel.invokeMethod("onPlay", arguments: nil)
            result(success)
            
        case "playFromFrame":
            if let args = call.arguments as? [String: Any],
               let frame = args["frame"] as? Double {
                let success = animation.play(fromFrame: Float(frame))
                print("🔴 DotLottie MacOS: ✅ Playing from frame: \(frame)")
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid frame argument", details: nil))
            }
            
        case "playFromProgress":
            if let args = call.arguments as? [String: Any],
               let progress = args["progress"] as? Double {
                let success = animation.play(fromProgress: Float(progress))
                print("🔴 DotLottie MacOS: ✅ Playing from progress: \(progress)")
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid progress argument", details: nil))
            }
            
        case "pause":
            let success = animation.pause()
            print("🔴 DotLottie MacOS: ✅ Pausing animation")
            methodChannel.invokeMethod("onPause", arguments: nil)
            result(success)
            
        case "stop":
            let success = animation.stop()
            print("🔴 DotLottie MacOS: ✅ Stopping animation")
            methodChannel.invokeMethod("onStop", arguments: nil)
            result(success)
            
            // Animation properties getters
        case "isPlaying":
            result(animation.isPlaying())
            
        case "isPaused":
            result(animation.isPaused())
            
        case "isStopped":
            result(animation.isStopped())
            
        case "isLoaded":
            result(animation.isLoaded())
            
        case "currentFrame":
            result(Double(animation.currentFrame()))
            
        case "totalFrames":
            result(Double(animation.totalFrames()))
            
        case "currentProgress":
            result(Double(animation.currentProgress()))
            
        case "duration":
            result(Double(animation.duration()))
            
        case "loopCount":
            result(animation.loopCount())
            
        case "speed":
            result(Double(animation.speed()))
            
        case "loop":
            result(animation.loop())
            
        case "autoplay":
            result(animation.autoplay())
            
        case "useFrameInterpolation":
            result(animation.useFrameInterpolation())
            
        case "segments":
            let segments = animation.segments()
            result([Double(segments.0), Double(segments.1)])
            
        case "mode":
            let mode = animation.mode()
            let modeString: String
            switch mode {
            case .forward:
                modeString = "forward"
            case .reverse:
                modeString = "reverse"
            case .bounce:
                modeString = "bounce"
            case .reverseBounce:
                modeString = "reverseBounce"
            @unknown default:
                modeString = "forward"
            }
            result(modeString)
            
            // Animation control setters
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
            
        case "setFrameInterpolation":
            if let args = call.arguments as? [String: Any],
               let useFrameInterpolation = args["useFrameInterpolation"] as? Bool {
                animation.setFrameInterpolation(useFrameInterpolation)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid frameInterpolation argument", details: nil))
            }
            
        case "setAutoplay":
            if let args = call.arguments as? [String: Any],
               let autoplay = args["autoplay"] as? Bool {
                animation.setAutoplay(autoplay: autoplay)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid autoplay argument", details: nil))
            }
            
        case "setBackgroundColor":
            if let args = call.arguments as? [String: Any],
               let colorString = args["color"] as? String,
               let color = parseColor(colorString) {
                // Convert NSColor to CIImage
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                let ciColor = CIColor(red: red, green: green, blue: blue, alpha: alpha)
                let ciImage = CIImage(color: ciColor)
                animation.setBackgroundColor(bgColor: ciImage)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid backgroundColor argument", details: nil))
            }
            
            // Theme methods
        case "setTheme":
            if let args = call.arguments as? [String: Any],
               let themeId = args["themeId"] as? String {
                let success = animation.setTheme(themeId)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid theme argument", details: nil))
            }
            
        case "setThemeData":
            if let args = call.arguments as? [String: Any],
               let themeData = args["themeData"] as? String {
                let success = animation.setThemeData(themeData)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid themeData argument", details: nil))
            }
            
        case "resetTheme":
            let success = animation.resetTheme()
            result(success)
            
        case "activeThemeId":
            result(animation.activeThemeId())
            
            // Animation loading methods
        case "loadAnimationById":
            if let args = call.arguments as? [String: Any],
               let animationId = args["animationId"] as? String {
                do {
                    try animation.loadAnimationById(animationId)
                    result(nil)
                } catch {
                    result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid animationId argument", details: nil))
            }
            
        case "activeAnimationId":
            result(animation.activeAnimationId())
            
            // Marker methods
        case "setMarker":
            if let args = call.arguments as? [String: Any],
               let marker = args["marker"] as? String {
                animation.setMarker(marker: marker)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid marker argument", details: nil))
            }
            
        case "markers":
            let markers = animation.markers()
            let markerDicts = markers.map { marker -> [String: Any] in
                return [
                    "name": marker.name,
                    "time": marker.time,
                    "duration": marker.duration
                ]
            }
            result(markerDicts)
            
            // Slots methods
        case "setSlots":
            if let args = call.arguments as? [String: Any],
               let slots = args["slots"] as? String {
                let success = animation.setSlots(slots)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slots argument", details: nil))
            }
            
            // Resize method
        case "resize":
            if let args = call.arguments as? [String: Any],
               let width = args["width"] as? Int,
               let height = args["height"] as? Int {
                animation.resize(width: width, height: height)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid resize arguments", details: nil))
            }
            
            // Layer methods
        case "getLayerBounds":
            if let args = call.arguments as? [String: Any],
               let layerName = args["layerName"] as? String {
                let bounds = animation.getLayerBounds(layerName: layerName)
                result(bounds.map { Double($0) })
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid layerName argument", details: nil))
            }
            
            // State machine methods
        case "stateMachineLoad":
            if let args = call.arguments as? [String: Any],
               let stateMachineId = args["stateMachineId"] as? String {
                let success = animation.stateMachineLoad(id: stateMachineId)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid stateMachineId argument", details: nil))
            }
            
        case "stateMachineLoadData":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String {
                let success = animation.stateMachineLoadData(data)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid data argument", details: nil))
            }
            
        case "stateMachineStart":
            let success = animation.stateMachineStart()
            result(success)
            
        case "stateMachineStop":
            let success = animation.stateMachineStop()
            result(success)
            
        case "stateMachinePostEvent":
            if let args = call.arguments as? [String: Any],
               let eventString = args["event"] as? String {
                // Parse the event string to create an Event enum
                // This is a simplified version - you may need to adjust based on your Event enum
                animation.stateMachineFire(event: eventString)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid event argument", details: nil))
            }
            
        case "stateMachineFire":
            if let args = call.arguments as? [String: Any],
               let event = args["event"] as? String {
                animation.stateMachineFire(event: event)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid event argument", details: nil))
            }
            
        case "stateMachineSetNumericInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String,
               let value = args["value"] as? Double {
                let success = animation.stateMachineSetNumericInput(key: key, value: Float(value))
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid numeric input arguments", details: nil))
            }
            
        case "stateMachineSetStringInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String,
               let value = args["value"] as? String {
                let success = animation.stateMachineSetStringInput(key: key, value: value)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid string input arguments", details: nil))
            }
            
        case "stateMachineSetBooleanInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String,
               let value = args["value"] as? Bool {
                let success = animation.stateMachineSetBooleanInput(key: key, value: value)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid boolean input arguments", details: nil))
            }
            
            // case "stateMachineGetNumericInput":
            //     if let args = call.arguments as? [String: Any],
            //        let key = args["key"] as? String {
            //         let value = animation.stateMachineGetNumericInput(key: key)
            //         result(Double(value))
            //     } else {
            //         result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            //     }
            
            // case "stateMachineGetStringInput":
            //     if let args = call.arguments as? [String: Any],
            //        let key = args["key"] as? String {
            //         let value = animation.stateMachineGetStringInput(key: key)
            //         result(value)
            //     } else {
            //         result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            //     }
            
            // case "stateMachineGetBooleanInput":
            //     if let args = call.arguments as? [String: Any],
            //        let key = args["key"] as? String {
            //         let value = animation.stateMachineGetBooleanInput(key: key)
            //         result(value)
            //     } else {
            //         result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            //     }
            
            // case "stateMachineGetInputs":
            //     let inputs = animation.stateMachineGetInputs()
            //     result(inputs)
            
        case "stateMachineCurrentState":
            result(animation.stateMachineCurrentState())
            
        case "stateMachineFrameworkSetup":
            result(animation.stateMachineFrameworkSetup())
            
            // case "getStateMachine":
            //     if let args = call.arguments as? [String: Any],
            //        let id = args["id"] as? String {
            //         let stateMachine = animation.getStateMachine(id)
            //         result(stateMachine)
            //     } else {
            //         result(FlutterError(code: "INVALID_ARGS", message: "Invalid id argument", details: nil))
            //     }
            
            // Manifest method
        case "manifest":
            if let manifest = animation.manifest() {
                // Convert Manifest to dictionary
                var manifestDict: [String: Any] = [:]
                // Add manifest properties here based on the Manifest structure
                // This is a simplified version - adjust based on actual Manifest structure
                result(manifestDict)
            } else {
                result(nil)
            }
            
            // Error methods
        case "error":
            result(animation.error())
            
        case "errorMessage":
            result(animation.errorMessage())
            
            // Render methods
        case "render":
            let success = animation.render()
            result(success)
            
        case "frameImage":
            if let image = animation.frameImage() {
                // Convert CGImage to Data
                let bitmap = NSBitmapImageRep(cgImage: image)
                if let pngData = bitmap.representation(using: .png, properties: [:]) {
                    result(FlutterStandardTypedData(bytes: pngData))
                } else {
                    result(nil)
                }
            } else {
                result(nil)
            }
            
        case "dispose":
            dispose()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func parseColor(_ colorString: String) -> NSColor? {
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
        
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func dispose() {
        guard !isDisposed else { return }
        isDisposed = true
        
        print("🔴 DotLottie MacOS: Disposing view")
        
        dotLottieAnimation = nil
        
        DispatchQueue.main.async {
            self._view.subviews.forEach { $0.removeFromSuperview() }
            self.hostingView = nil
        }
    }
    
    deinit {
        print("🔴 DotLottie MacOS: deinit called")
        dispose()
    }
}

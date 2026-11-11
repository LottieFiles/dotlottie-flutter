import FlutterMacOS
import AppKit
import DotLottie
import SwiftUI

class AnimationObserver: Observer {
    private let methodchannel: FlutterMethodChannel

    init(methodChannel: FlutterMethodChannel) {
        self.methodchannel = methodChannel
    }

    func onComplete() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onComplete", arguments: nil) }
    }

    func onFrame(frameNo: Float) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onFrame", arguments: frameNo) }
    }

    func onLoad() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onLoad", arguments: nil) }
    }

    func onLoadError() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onLoadError", arguments: nil) }
    }

    func onLoop(loopCount: UInt32) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onLoop", arguments: loopCount) }
    }

    func onPause() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onPause", arguments: nil) }
    }

    func onPlay() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onPlay", arguments: nil) }
    }

    func onRender(frameNo: Float) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onRender", arguments: frameNo) }
    }

    func onStop() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("onStop", arguments: nil) }
    }
}

class FlutterStateMachineObserver: StateMachineObserver {
    private let methodchannel: FlutterMethodChannel

    init(methodChannel: FlutterMethodChannel) {
        self.methodchannel = methodChannel
    }

    func onBooleanInputValueChange(inputName: String, oldValue: Bool, newValue: Bool) {
        DispatchQueue.main.async {
            self.methodchannel.invokeMethod(
                "stateMachineOnBooleanInputValueChange",
                arguments: ["inputName": inputName, "oldValue": oldValue, "newValue": newValue]
            )
        }
    }

    func onError(message: String) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnError", arguments: message) }
    }

    func onNumericInputValueChange(inputName: String, oldValue: Float, newValue: Float) {
        DispatchQueue.main.async {
            self.methodchannel.invokeMethod(
                "stateMachineOnNumericInputValueChange",
                arguments: ["inputName": inputName, "oldValue": oldValue, "newValue": newValue]
            )
        }
    }

    func onStart() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnStart", arguments: nil) }
    }

    func onStop() {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnStop", arguments: nil) }
    }

    func onStringInputValueChange(inputName: String, oldValue: String, newValue: String) {
        DispatchQueue.main.async {
            self.methodchannel.invokeMethod(
                "stateMachineOnStringInputValueChange",
                arguments: ["inputName": inputName, "oldValue": oldValue, "newValue": newValue]
            )
        }
    }

    func onInputFired(inputName: String) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnInputFired", arguments: inputName) }
    }

    func onCustomEvent(message: String) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnCustomEvent", arguments: message) }
    }

    func onStateEntered(enteringState: String) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnStateEntered", arguments: enteringState) }
    }

    func onStateExit(leavingState: String) {
        DispatchQueue.main.async { self.methodchannel.invokeMethod("stateMachineOnStateExit", arguments: leavingState) }
    }

    func onTransition(previousState: String, newState: String) {
        DispatchQueue.main.async {
            self.methodchannel.invokeMethod(
                "stateMachineOnTransition",
                arguments: ["previousState": previousState, "newState": newState]
            )
        }
    }
}

class DotLottieFlutterPlatformView: NSObject {
    private static let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private var _view: NSView
    private var dotLottieAnimation: DotLottieAnimation?
    private lazy var animationObserver: AnimationObserver = {
        return AnimationObserver(methodChannel: methodChannel)
    }()
    private lazy var stateMachineObserver: FlutterStateMachineObserver = {
        return FlutterStateMachineObserver(methodChannel: methodChannel)
    }()
    private var hostingController: NSHostingController<DotLottieView>?
    private var methodChannel: FlutterMethodChannel
    private var isDisposed = false
    private var viewId: Int64
    private var pendingURLTask: URLSessionDataTask?
    
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
        let autoplay = arguments["autoplay"] as? Bool ?? false
        let loop = arguments["loop"] as? Bool ?? false
        let loopCount = arguments["loopCount"] as? Int ?? 0
        let mode = arguments["mode"] as? String ?? "Forward"
        
        let convertedMode = {
            switch mode {
            case "forward":
                return Mode.forward
            case "reverse":
                return Mode.reverse
            case "bounce":
                return Mode.bounce
            case "reverse-bounce", "reverseBounce":
                return Mode.reverseBounce
            default:
                return .forward
            }
        }
        let speed = arguments["speed"] as? Double ?? 1.0
        let useFrameInterpolation = arguments["useFrameInterpolation"] as? Bool ?? false
        let segment = arguments["segment"] as? [Float] ?? []
        let convertedSegment: ((Float, Float))? = {
            if segment.count >= 2 {
                return (segment[0], segment[1])
            }
            return nil
        }()
        let backgroundColor = arguments["backgroundColor"] as? String
        let marker = arguments["marker"] as? String ?? ""
        let themeId = arguments["themeId"] as? String ?? ""
        let stateMachineId = arguments["stateMachineId"] as? String ?? ""
        let animationId = arguments["animationId"] as? String ?? ""
        let sourceType = arguments["sourceType"] as? String
        let source = arguments["source"] as? String
        let width = arguments["width"] as? Int
        let height = arguments["height"] as? Int
        let fitString = arguments["fit"] as? String
        let convertedFit: Fit? = {
            guard let fitString = fitString else { return nil }
            switch fitString {
            case "fill":      return .fill
            case "cover":     return .cover
            case "fitWidth":  return .fitWidth
            case "fitHeight": return .fitHeight
            case "none":      return Fit.none
            default:          return .contain
            }
        }()
        let layout: DotLottie.Layout? = convertedFit.map { DotLottie.Layout(fit: $0, alignX: 0.5, alignY: 0.5) }

        guard let sourceType = sourceType else {
            return
        }

        var config = AnimationConfig(
            autoplay: autoplay,
            loop: loop,
            loopCount: loopCount,
            mode: convertedMode(),
            speed: Float(speed),
            useFrameInterpolation: useFrameInterpolation,
            segments: convertedSegment,
            layout: layout,
            marker: marker,
            themeId: themeId,
            stateMachineId: stateMachineId
        )
        config.animationId = animationId

        if let externalAssets = arguments["externalAssets"] as? [String: Any] {
            let assets: [String: Data] = externalAssets.compactMapValues {
                ($0 as? FlutterStandardTypedData)?.data
            }
            // The core reports a relative asset path with a leading slash.
            config.assetResolver = { src in assets[src] ?? (src.hasPrefix("/") ? assets[String(src.dropFirst())] : nil) }
        }

        if let w = width {
            config.width = w
        }
        if let h = height {
            config.height = h
        }   

        if let bgColor = backgroundColor, let color = parseColor(bgColor) {
            _view.layer?.backgroundColor = color.cgColor
        }

        switch sourceType {
        case "url":
            // After download, create the animation on the main thread so it can never
            // run concurrently with the display-link tick(), which also runs on the main
            // thread.
            guard let urlString = source, let url = URL(string: urlString) else {
                // Defer by one run-loop turn so _onPlatformViewCreated on the Dart
                // side has a chance to register its setMethodCallHandler before we
                // invoke the channel, otherwise the message is silently dropped.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self, !self.isDisposed else { return }
                    self.methodChannel.invokeMethod("onLoadError", arguments: nil)
                }
                return
            }
            let task = Self.urlSession.dataTask(with: url) { [weak self] data, _, error in
                guard let self = self else { return }
                guard let data = data, error == nil else {
                    DispatchQueue.main.async {
                        guard !self.isDisposed else { return }
                        self.methodChannel.invokeMethod("onLoadError", arguments: nil)
                    }
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, !self.isDisposed else { return }
                    let animation = DotLottieAnimation(dotLottieData: data, config: config)
                    self.mountAnimation(animation)
                    self.methodChannel.invokeMethod("onLoad", arguments: nil)
                }
            }
            pendingURLTask = task
            task.resume()
            return

        case "data":
            if let flutterData = arguments["source"] as? FlutterStandardTypedData {
                let animation = DotLottieAnimation(dotLottieData: flutterData.data, config: config)
                mountAnimation(animation)
                methodChannel.invokeMethod("onLoad", arguments: nil)
            }
            return

        case "json":
            if let src = source {
                let animation = DotLottieAnimation(animationData: src, config: config)
                mountAnimation(animation)
            }
            methodChannel.invokeMethod("onLoad", arguments: nil)
            return

        default:
            return
        }
    }

    // Attaches a fully-loaded animation to the view hierarchy.  Must be called on the main
    // thread.  Keeping this separate means URL sources can defer mounting until after load,
    // preventing the MTKView display link from ticking an unloaded canvas.
    private func mountAnimation(_ animation: DotLottieAnimation) {
        dotLottieAnimation = animation
        animation.subscribe(observer: animationObserver)
        let _ = animation.stateMachineSubscribe(stateMachineObserver)

        let animationView = animation.view() as DotLottieView
        let hosting = NSHostingController(rootView: animationView)
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = .clear
        hosting.view.frame = _view.bounds
        hosting.view.autoresizingMask = [.width, .height]
        _view.addSubview(hosting.view)
        hostingController = hosting
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
        
        switch call.method {
        case "play":
            let success = animation.play()
            result(success)
            
        case "pause":
            let success = animation.pause()
            result(success)
            
        case "stop":
            let success = animation.stop()
            result(success)
            
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
                case "reverseBounce", "reverse-bounce":
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
            
        case "setLoopCount":
            if let args = call.arguments as? [String: Any],
               let loopCount = args["loopCount"] as? Int {
                animation.setLoopCount(loopCount)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid loopCount argument", details: nil))
            }

        case "setAudioVolume":
            if let args = call.arguments as? [String: Any],
               let volume = args["volume"] as? Double {
                animation.setAudioVolume(volume: Float(volume))
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid volume argument", details: nil))
            }

        case "audioVolume":
            result(Double(animation.audioVolume()))

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
            
        case "loadAnimation":
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
                    "start": marker.time,
                    "end": marker.time + marker.duration,
                    "time": marker.time,
                    "duration": marker.duration
                ]
            }
            result(markerDicts)
            
        case "setSlots":
            if let args = call.arguments as? [String: Any],
               let slots = args["slots"] as? String {
                let success = animation.setSlots(slots)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slots argument", details: nil))
            }
            
        case "setSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let json = args["json"] as? String {
                result(animation.setSlot(slotId: slotId, json: json))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setSlot arguments", details: nil))
            }

        case "setColorSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let r = args["r"] as? Double,
               let g = args["g"] as? Double,
               let b = args["b"] as? Double {
                result(animation.setColorSlot(slotId: slotId, r: Float(r), g: Float(g), b: Float(b)))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setColorSlot arguments", details: nil))
            }

        case "setScalarSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let value = args["value"] as? Double {
                result(animation.setScalarSlot(slotId: slotId, value: Float(value)))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setScalarSlot arguments", details: nil))
            }

        case "setTextSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let text = args["text"] as? String {
                result(animation.setTextSlot(slotId: slotId, text: text))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setTextSlot arguments", details: nil))
            }

        case "setVectorSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let x = args["x"] as? Double,
               let y = args["y"] as? Double {
                result(animation.setVectorSlot(slotId: slotId, x: Float(x), y: Float(y)))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setVectorSlot arguments", details: nil))
            }

        case "setPositionSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let x = args["x"] as? Double,
               let y = args["y"] as? Double {
                result(animation.setPositionSlot(slotId: slotId, x: Float(x), y: Float(y)))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setPositionSlot arguments", details: nil))
            }

        case "setImageSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let src = args["src"] as? String {
                let success = src.hasPrefix("data:")
                    ? animation.setImageSlotDataUrl(slotId: slotId, dataUrl: src)
                    : animation.setImageSlotPath(slotId: slotId, path: src)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setImageSlot arguments", details: nil))
            }

        case "setBezierPathSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String,
               let vertices = toPoints(args["vertices"]) {
                let closed = args["closed"] as? Bool ?? false
                let success = animation.setBezierPathSlot(
                    slotId: slotId,
                    vertices: vertices,
                    closed: closed,
                    inTangents: toPoints(args["inTangents"]),
                    outTangents: toPoints(args["outTangents"])
                )
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid setBezierPathSlot arguments", details: nil))
            }

        case "clearSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String {
                result(animation.clearSlot(slotId: slotId))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slotId argument", details: nil))
            }

        case "clearSlots":
            result(animation.clearSlots())

        case "resetSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String {
                result(animation.resetSlot(slotId: slotId))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slotId argument", details: nil))
            }

        case "resetSlots":
            result(animation.resetSlots())

        case "getSlotIds":
            result(animation.getSlotIds())

        case "getSlotType":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String {
                result(animation.getSlotType(slotId: slotId))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slotId argument", details: nil))
            }

        case "getSlot":
            if let args = call.arguments as? [String: Any],
               let slotId = args["slotId"] as? String {
                result(animation.getSlot(slotId: slotId))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slotId argument", details: nil))
            }

        case "getSlots":
            result(animation.getSlots())

        case "resize":
            if let args = call.arguments as? [String: Any],
               let width = args["width"] as? Int,
               let height = args["height"] as? Int {
                animation.resize(width: width, height: height)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid resize arguments", details: nil))
            }

        case "setLayout":
            if let args = call.arguments as? [String: Any],
               let fitString = args["fit"] as? String {
                let fit: Fit
                switch fitString {
                case "fill":      fit = .fill
                case "cover":     fit = .cover
                case "fitWidth":  fit = .fitWidth
                case "fitHeight": fit = .fitHeight
                case "none":      fit = Fit.none
                default:          fit = .contain
                }
                let alignX = Float(args["alignX"] as? Double ?? 0.5)
                let alignY = Float(args["alignY"] as? Double ?? 0.5)
                animation.setLayout(layout: DotLottie.Layout(fit: fit, alignX: alignX, alignY: alignY))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid layout arguments", details: nil))
            }

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
            
        case "stateMachineGetNumericInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                let value = animation.stateMachineGetNumericInput(key: key)
                result(Double(value))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }
            
        case "stateMachineGetStringInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                let value = animation.stateMachineGetStringInput(key: key)
                result(value)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }
            
        case "stateMachineGetBooleanInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                let value = animation.stateMachineGetBooleanInput(key: key)
                result(value)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }
            
        case "stateMachineGetInputs":
            let inputs = animation.stateMachineGetInputs()
            result(inputs)
            
        case "stateMachineCurrentState":
            result(animation.stateMachineCurrentState())
                        
        case "stateMachineStatus":
            result(animation.stateMachineStatus())

        case "stateMachineSetSeed":
            if let args = call.arguments as? [String: Any],
               let seed = args["seed"] as? Int {
                result(animation.stateMachineSetSeed(UInt64(bitPattern: Int64(seed))))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid seed argument", details: nil))
            }

        case "stateMachineOverrideState":
            if let args = call.arguments as? [String: Any],
               let state = args["state"] as? String {
                let immediate = args["immediate"] as? Bool ?? false
                result(animation.stateMachineOverrideCurrentState(state, immediate: immediate))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid state argument", details: nil))
            }

        case "stateMachineResetInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                result(animation.stateMachineResetInput(key: key))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }

        case "getStateMachine":
            if let args = call.arguments as? [String: Any],
                let id = args["id"] as? String {
                let stateMachine = animation.getStateMachine(id)
                result(stateMachine)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid id argument", details: nil))
            }
            
        case "manifest":
            if let manifest = animation.manifest() {
                // Convert Manifest to dictionary
                var manifestDict: [String: Any] = [:]
                
                manifestDict["version"] = manifest.version
                manifestDict["generator"] = manifest.generator
                
                // Convert ManifestInitial
                if let initial = manifest.initial {
                    var initialDict: [String: Any?] = [:]
                    initialDict["animation"] = initial.animation
                    initialDict["stateMachine"] = initial.stateMachine
                    manifestDict["initial"] = initialDict
                }
                
                manifestDict["animations"] = manifest.animations.map { animation in
                    var animDict: [String: Any?] = [:]
                    animDict["id"] = animation.id
                    animDict["name"] = animation.name
                    animDict["initialTheme"] = animation.initialTheme
                    animDict["themes"] = animation.themes
                    animDict["background"] = animation.background
                    return animDict
                }
                
                // Convert ManifestTheme array
                if let themes = manifest.themes {
                    manifestDict["themes"] = themes.map { theme in
                        var themeDict: [String: Any?] = [:]
                        themeDict["id"] = theme.id
                        themeDict["name"] = theme.name
                        return themeDict
                    }
                }
                
                // Convert ManifestStateMachine array
                if let stateMachines = manifest.stateMachines {
                    manifestDict["stateMachines"] = stateMachines.map { stateMachine in
                        var smDict: [String: Any?] = [:]
                        smDict["id"] = stateMachine.id
                        smDict["name"] = stateMachine.name
                        return smDict
                    }
                }
                
                result(manifestDict)
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
    
    private func toPoints(_ value: Any?) -> [CGPoint]? {
        guard let pairs = value as? [[Double]] else { return nil }
        var points: [CGPoint] = []
        for pair in pairs {
            guard pair.count >= 2 else { return nil }
            points.append(CGPoint(x: pair[0], y: pair[1]))
        }
        return points
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
    
    private func dispose() {
        guard !isDisposed else { return }
        isDisposed = true

        pendingURLTask?.cancel()
        pendingURLTask = nil

        dotLottieAnimation?.stop()

        let _ = dotLottieAnimation?.stateMachineUnsubscribe(self.stateMachineObserver)
        dotLottieAnimation?.unsubscribe(observer: self.animationObserver)

        // Tear down the hosting view synchronously so the Metal/CV display link stops
        // driving the SwiftUI render tree before we release the C++ objects.
        let hc = hostingController
        let view = _view
        let animToRelease = dotLottieAnimation
        hostingController = nil
        dotLottieAnimation = nil

        hc?.view.removeFromSuperview()
        view.subviews.forEach { $0.removeFromSuperview() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            _ = animToRelease
        }
    }

    deinit {
        dispose()
    }
}
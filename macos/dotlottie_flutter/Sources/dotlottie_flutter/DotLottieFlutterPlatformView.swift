import FlutterMacOS
import AppKit
import DotLottie

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
    private var renderer: DotLottieFlutterRenderer?
    private lazy var animationObserver: AnimationObserver = {
        return AnimationObserver(methodChannel: methodChannel)
    }()
    private lazy var stateMachineObserver: FlutterStateMachineObserver = {
        return FlutterStateMachineObserver(methodChannel: methodChannel)
    }()
    private var methodChannel: FlutterMethodChannel
    private var isDisposed = false
    private var viewId: Int64
    private var pendingURLTask: URLSessionDataTask?

    private var requestedWebGPU = false

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
            case "reverse-bounce":
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
        requestedWebGPU = arguments["useWebGPU"] as? Bool ?? false
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

        if let w = width {
            config.width = w
        }
        if let h = height {
            config.height = h
        }   

        if let bgColor = backgroundColor, let color = DotLottieColor.nsColor(bgColor) {
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
                    self.startRenderer(config: config, source: .dotLottieData(data))
                }
            }
            pendingURLTask = task
            task.resume()
            return

        case "data":
            if let flutterData = arguments["source"] as? FlutterStandardTypedData {
                startRenderer(config: config, source: .dotLottieData(flutterData.data))
            }
            return

        case "json":
            if let src = source {
                startRenderer(config: config, source: .json(src))
            }
            return

        default:
            return
        }
    }

    private func startRenderer(config: AnimationConfig, source: DotLottieRendererSource) {
        if requestedWebGPU, DotLottieWebGPURenderer.isSupported {
            mount(DotLottieWebGPURenderer(config: config, source: source))
            return
        }
        mount(DotLottieSoftwareRenderer(config: config, source: source))
    }

    private func mount(_ renderer: DotLottieFlutterRenderer) {
        self.renderer = renderer
        renderer.subscribe(observer: animationObserver)
        let _ = renderer.stateMachineSubscribe(stateMachineObserver)
        renderer.mount(in: _view)

        // The software renderer loaded before the observer above was attached.
        if !renderer.emitsLoadEvent {
            methodChannel.invokeMethod("onLoad", arguments: nil)
        }
    }

    private func teardown(_ renderer: DotLottieFlutterRenderer) {
        renderer.stop()
        let _ = renderer.stateMachineUnsubscribe(stateMachineObserver)
        renderer.unsubscribe(observer: animationObserver)
        renderer.unmount()
    }

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard !isDisposed else {
            result(FlutterError(code: "DISPOSED", message: "View has been disposed", details: nil))
            return
        }
        
        switch call.method {
        case "renderer":
            result(renderer?.kind.rawValue)
            return

        case "dispose":
            dispose()
            result(nil)
            return

        default:
            break
        }

        guard let renderer = renderer else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Animation not initialized", details: nil))
            return
        }

        switch call.method {
        case "play":
            let success = renderer.play()
            result(success)
            
        case "pause":
            let success = renderer.pause()
            result(success)
            
        case "stop":
            let success = renderer.stop()
            result(success)
            
        case "isPlaying":
            result(renderer.isPlaying())
            
        case "isPaused":
            result(renderer.isPaused())
            
        case "isStopped":
            result(renderer.isStopped())
            
        case "isLoaded":
            result(renderer.isLoaded())
            
        case "currentFrame":
            result(Double(renderer.currentFrame()))
            
        case "totalFrames":
            result(Double(renderer.totalFrames()))
            
        case "currentProgress":
            result(Double(renderer.currentProgress()))
            
        case "duration":
            result(Double(renderer.duration()))
            
        case "loopCount":
            result(renderer.loopCount())
            
        case "speed":
            result(Double(renderer.speed()))
            
        case "loop":
            result(renderer.loop())
            
        case "autoplay":
            result(renderer.autoplay())
            
        case "useFrameInterpolation":
            result(renderer.useFrameInterpolation())
            
        case "segments":
            let segments = renderer.segments()
            result([Double(segments.0), Double(segments.1)])
            
        case "mode":
            let mode = renderer.mode()
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
                renderer.setSpeed(speed: Float(speed))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid speed argument", details: nil))
            }
            
        case "setLoop":
            if let args = call.arguments as? [String: Any],
               let loop = args["loop"] as? Bool {
                renderer.setLoop(loop: loop)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid loop argument", details: nil))
            }
            
        case "setFrame":
            if let args = call.arguments as? [String: Any],
               let frame = args["frame"] as? Double {
                let success = renderer.setFrame(frame: Float(frame))
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid frame argument", details: nil))
            }
            
        case "setProgress":
            if let args = call.arguments as? [String: Any],
               let progress = args["progress"] as? Double {
                let success = renderer.setProgress(progress: Float(progress))
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid progress argument", details: nil))
            }
            
        case "setSegments":
            if let args = call.arguments as? [String: Any],
               let start = args["start"] as? Double,
               let end = args["end"] as? Double {
                renderer.setSegments(segments: (Float(start), Float(end)))
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
                renderer.setMode(mode: mode)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid mode argument", details: nil))
            }
            
        case "setFrameInterpolation":
            if let args = call.arguments as? [String: Any],
               let useFrameInterpolation = args["useFrameInterpolation"] as? Bool {
                renderer.setFrameInterpolation(useFrameInterpolation)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid frameInterpolation argument", details: nil))
            }
            
        case "setBackgroundColor":
            guard let args = call.arguments as? [String: Any],
                  let colorString = args["color"] as? String,
                  DotLottieColor.argb(colorString) != nil else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid backgroundColor argument", details: nil))
                return
            }
            renderer.setBackgroundColor(hex: colorString)
            // Stored but never shown under WebGPU — do not report a success that does nothing.
            if renderer.supportsBackgroundColor {
                result(nil)
            } else {
                result(FlutterError(
                    code: "UNSUPPORTED",
                    message: "setBackgroundColor is not supported by the WebGPU renderer",
                    details: nil
                ))
            }
            
        case "setTheme":
            if let args = call.arguments as? [String: Any],
               let themeId = args["themeId"] as? String {
                let success = renderer.setTheme(themeId)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid theme argument", details: nil))
            }
            
        case "setThemeData":
            if let args = call.arguments as? [String: Any],
               let themeData = args["themeData"] as? String {
                let success = renderer.setThemeData(themeData)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid themeData argument", details: nil))
            }
            
        case "resetTheme":
            let success = renderer.resetTheme()
            result(success)
            
        case "activeThemeId":
            result(renderer.activeThemeId())
            
        case "loadAnimation":
            if let args = call.arguments as? [String: Any],
               let animationId = args["animationId"] as? String {
                do {
                    try renderer.loadAnimationById(animationId)
                    result(nil)
                } catch {
                    result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid animationId argument", details: nil))
            }
            
        case "activeAnimationId":
            result(renderer.activeAnimationId())
            
        case "setMarker":
            if let args = call.arguments as? [String: Any],
               let marker = args["marker"] as? String {
                renderer.setMarker(marker: marker)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid marker argument", details: nil))
            }
            
        case "markers":
            let markers = renderer.markers()
            let markerDicts = markers.map { marker -> [String: Any] in
                return [
                    "name": marker.name,
                    "time": marker.time,
                    "duration": marker.duration
                ]
            }
            result(markerDicts)
            
        case "setSlots":
            if let args = call.arguments as? [String: Any],
               let slots = args["slots"] as? String {
                let success = renderer.setSlots(slots)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid slots argument", details: nil))
            }
            
        case "resize":
            if let args = call.arguments as? [String: Any],
               let width = args["width"] as? Int,
               let height = args["height"] as? Int {
                renderer.resize(width: width, height: height)
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
                renderer.setLayout(layout: DotLottie.Layout(fit: fit, alignX: alignX, alignY: alignY))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid layout arguments", details: nil))
            }

        case "stateMachineLoad":
            if let args = call.arguments as? [String: Any],
               let stateMachineId = args["stateMachineId"] as? String {
                let success = renderer.stateMachineLoad(id: stateMachineId)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid stateMachineId argument", details: nil))
            }
            
        case "stateMachineLoadData":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String {
                let success = renderer.stateMachineLoadData(data)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid data argument", details: nil))
            }
            
        case "stateMachineStart":
            let success = renderer.stateMachineStart()
            result(success)
            
        case "stateMachineStop":
            let success = renderer.stateMachineStop()
            result(success)
            
        case "stateMachineFire":
            if let args = call.arguments as? [String: Any],
               let event = args["event"] as? String {
                renderer.stateMachineFire(event: event)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid event argument", details: nil))
            }
            
        case "stateMachineSetNumericInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String,
               let value = args["value"] as? Double {
                let success = renderer.stateMachineSetNumericInput(key: key, value: Float(value))
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid numeric input arguments", details: nil))
            }
            
        case "stateMachineSetStringInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String,
               let value = args["value"] as? String {
                let success = renderer.stateMachineSetStringInput(key: key, value: value)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid string input arguments", details: nil))
            }
            
        case "stateMachineSetBooleanInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String,
               let value = args["value"] as? Bool {
                let success = renderer.stateMachineSetBooleanInput(key: key, value: value)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid boolean input arguments", details: nil))
            }
            
        case "stateMachineGetNumericInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                let value = renderer.stateMachineGetNumericInput(key: key)
                result(Double(value))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }
            
        case "stateMachineGetStringInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                let value = renderer.stateMachineGetStringInput(key: key)
                result(value)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }
            
        case "stateMachineGetBooleanInput":
            if let args = call.arguments as? [String: Any],
               let key = args["key"] as? String {
                let value = renderer.stateMachineGetBooleanInput(key: key)
                result(value)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid key argument", details: nil))
            }
            
        case "stateMachineGetInputs":
            let inputs = renderer.stateMachineGetInputs()
            result(inputs)
            
        case "stateMachineCurrentState":
            result(renderer.stateMachineCurrentState())
                        
        case "getStateMachine":
            if let args = call.arguments as? [String: Any],
                let id = args["id"] as? String {
                let stateMachine = renderer.getStateMachine(id)
                result(stateMachine)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid id argument", details: nil))
            }
            
        case "manifest":
            if let manifest = renderer.manifest() {
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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func dispose() {
        guard !isDisposed else { return }
        isDisposed = true

        pendingURLTask?.cancel()
        pendingURLTask = nil

        // Synchronous: the display link must stop before the C++ objects are released.
        let rendererToRelease = renderer
        renderer = nil
        if let rendererToRelease = rendererToRelease { teardown(rendererToRelease) }

        _view.subviews.forEach { $0.removeFromSuperview() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            _ = rendererToRelease
        }
    }

    deinit {
        dispose()
    }
}
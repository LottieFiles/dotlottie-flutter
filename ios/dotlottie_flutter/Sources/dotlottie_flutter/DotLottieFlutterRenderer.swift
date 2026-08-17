import Flutter
import UIKit
import SwiftUI
import CoreImage
import Metal
import DotLottie

// MARK: - Renderer kind

enum DotLottieRendererKind: String {
    case software = "sw"
    case webgpu = "wg"
}

enum DotLottieRendererSource {
    case dotLottieData(Data)
    case json(String)
}

struct DotLottieRendererError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Utils

enum DotLottieColor {
    /// Parses `RRGGBB` or `AARRGGBB`, with or without a leading `#`.
    static func argb(_ colorString: String) -> UInt32? {
        var hexString = colorString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb) else { return nil }

        switch hexString.count {
        case 6:  return UInt32(truncatingIfNeeded: rgb) | 0xFF00_0000
        case 8:  return UInt32(truncatingIfNeeded: rgb)
        default: return nil
        }
    }

    static func uiColor(_ colorString: String) -> UIColor? {
        guard let argb = argb(colorString) else { return nil }
        return UIColor(
            red: CGFloat((argb & 0x00FF_0000) >> 16) / 255.0,
            green: CGFloat((argb & 0x0000_FF00) >> 8) / 255.0,
            blue: CGFloat(argb & 0x0000_00FF) / 255.0,
            alpha: CGFloat((argb & 0xFF00_0000) >> 24) / 255.0
        )
    }
}

// MARK: - Renderer protocol

protocol DotLottieFlutterRenderer: AnyObject {
    var kind: DotLottieRendererKind { get }

    /// `false` for WebGPU: its surface is rendered opaque upstream.
    var supportsBackgroundColor: Bool { get }

    /// `false` for the software renderer, which loads inside its initialiser before any
    /// observer is attached — the platform view has to synthesise `onLoad` for it.
    var emitsLoadEvent: Bool { get }

    // Lifecycle
    func mount(in container: UIView)
    func unmount()

    // Observers
    func subscribe(observer: Observer)
    func unsubscribe(observer: Observer)
    @discardableResult func stateMachineSubscribe(_ observer: StateMachineObserver) -> Bool
    @discardableResult func stateMachineUnsubscribe(_ observer: StateMachineObserver) -> Bool

    // Playback
    @discardableResult func play() -> Bool
    @discardableResult func pause() -> Bool
    @discardableResult func stop() -> Bool
    func isPlaying() -> Bool
    func isPaused() -> Bool
    func isStopped() -> Bool
    func isLoaded() -> Bool

    // Timeline
    func currentFrame() -> Float
    func totalFrames() -> Float
    func currentProgress() -> Float
    func duration() -> Float
    func loopCount() -> Int
    @discardableResult func setFrame(frame: Float) -> Bool
    @discardableResult func setProgress(progress: Float) -> Bool

    // Configuration
    func speed() -> Float
    func loop() -> Bool
    func autoplay() -> Bool
    func useFrameInterpolation() -> Bool
    func segments() -> (Float, Float)
    func mode() -> Mode
    func setSpeed(speed: Float)
    func setLoop(loop: Bool)
    func setSegments(segments: (Float, Float))
    func setMode(mode: Mode)
    func setFrameInterpolation(_ useFrameInterpolation: Bool)
    func setBackgroundColor(hex: String)
    func setLayout(layout: DotLottie.Layout)
    func resize(width: Int, height: Int)

    // Theming & slots
    @discardableResult func setTheme(_ themeId: String) -> Bool
    @discardableResult func setThemeData(_ themeData: String) -> Bool
    @discardableResult func resetTheme() -> Bool
    func activeThemeId() -> String
    @discardableResult func setSlots(_ slots: String) -> Bool

    // Multi-animation & markers
    func loadAnimationById(_ animationId: String) throws
    func activeAnimationId() -> String
    func setMarker(marker: String)
    func markers() -> [Marker]
    func manifest() -> Manifest?

    // State machine
    @discardableResult func stateMachineLoad(id: String) -> Bool
    @discardableResult func stateMachineLoadData(_ data: String) -> Bool
    @discardableResult func stateMachineStart() -> Bool
    @discardableResult func stateMachineStop() -> Bool
    func stateMachineFire(event: String)
    @discardableResult func stateMachineSetNumericInput(key: String, value: Float) -> Bool
    @discardableResult func stateMachineSetStringInput(key: String, value: String) -> Bool
    @discardableResult func stateMachineSetBooleanInput(key: String, value: Bool) -> Bool
    func stateMachineGetNumericInput(key: String) -> Float
    func stateMachineGetStringInput(key: String) -> String
    func stateMachineGetBooleanInput(key: String) -> Bool
    func stateMachineGetInputs() -> [String: String]
    func stateMachineCurrentState() -> String
    func getStateMachine(_ id: String) -> String
}

// MARK: - Software renderer

final class DotLottieSoftwareRenderer: DotLottieFlutterRenderer {
    let kind: DotLottieRendererKind = .software
    let supportsBackgroundColor = true
    let emitsLoadEvent = false

    private let animation: DotLottieAnimation
    private var hostingController: UIHostingController<DotLottieView>?

    init(config: AnimationConfig, source: DotLottieRendererSource) {
        switch source {
        case .dotLottieData(let data):
            animation = DotLottieAnimation(dotLottieData: data, config: config)
        case .json(let json):
            animation = DotLottieAnimation(animationData: json, config: config)
        }
    }

    func mount(in container: UIView) {
        let hosting = UIHostingController(rootView: animation.view() as DotLottieView)

        // The hosting controller sits outside any view-controller hierarchy, so UIKit's
        // safe-area propagation would inset the animation inside the platform view.
        if #available(iOS 16.4, *) {
            hosting.safeAreaRegions = []
        }
        hosting.view.backgroundColor = UIColor.clear
        hosting.view.frame = container.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(hosting.view)
        hostingController = hosting
    }

    func unmount() {
        // Synchronous: the display link must stop before the C++ objects are released.
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }

    func subscribe(observer: Observer) { animation.subscribe(observer: observer) }
    func unsubscribe(observer: Observer) { animation.unsubscribe(observer: observer) }
    func stateMachineSubscribe(_ observer: StateMachineObserver) -> Bool {
        animation.stateMachineSubscribe(observer)
    }
    func stateMachineUnsubscribe(_ observer: StateMachineObserver) -> Bool {
        animation.stateMachineUnsubscribe(observer)
    }

    func play() -> Bool { animation.play() }
    func pause() -> Bool { animation.pause() }
    func stop() -> Bool { animation.stop() }
    func isPlaying() -> Bool { animation.isPlaying() }
    func isPaused() -> Bool { animation.isPaused() }
    func isStopped() -> Bool { animation.isStopped() }
    func isLoaded() -> Bool { animation.isLoaded() }

    func currentFrame() -> Float { animation.currentFrame() }
    func totalFrames() -> Float { animation.totalFrames() }
    func currentProgress() -> Float { animation.currentProgress() }
    func duration() -> Float { animation.duration() }
    func loopCount() -> Int { animation.loopCount() }
    func setFrame(frame: Float) -> Bool { animation.setFrame(frame: frame) }
    func setProgress(progress: Float) -> Bool { animation.setProgress(progress: progress) }

    func speed() -> Float { animation.speed() }
    func loop() -> Bool { animation.loop() }
    func autoplay() -> Bool { animation.autoplay() }
    func useFrameInterpolation() -> Bool { animation.useFrameInterpolation() }
    func segments() -> (Float, Float) { animation.segments() }
    func mode() -> Mode { animation.mode() }
    func setSpeed(speed: Float) { animation.setSpeed(speed: speed) }
    func setLoop(loop: Bool) { animation.setLoop(loop: loop) }
    func setSegments(segments: (Float, Float)) { animation.setSegments(segments: segments) }
    func setMode(mode: Mode) { animation.setMode(mode: mode) }
    func setFrameInterpolation(_ useFrameInterpolation: Bool) {
        animation.setFrameInterpolation(useFrameInterpolation)
    }
    func setBackgroundColor(hex: String) {
        guard let color = DotLottieColor.uiColor(hex) else { return }
        animation.setBackgroundColor(bgColor: CIImage(color: CIColor(color: color)))
    }
    func setLayout(layout: DotLottie.Layout) { animation.setLayout(layout: layout) }
    func resize(width: Int, height: Int) { animation.resize(width: width, height: height) }

    func setTheme(_ themeId: String) -> Bool { animation.setTheme(themeId) }
    func setThemeData(_ themeData: String) -> Bool { animation.setThemeData(themeData) }
    func resetTheme() -> Bool { animation.resetTheme() }
    func activeThemeId() -> String { animation.activeThemeId() }
    func setSlots(_ slots: String) -> Bool { animation.setSlots(slots) }

    func loadAnimationById(_ animationId: String) throws {
        try animation.loadAnimationById(animationId)
    }
    func activeAnimationId() -> String { animation.activeAnimationId() }
    func setMarker(marker: String) { animation.setMarker(marker: marker) }
    func markers() -> [Marker] { animation.markers() }
    func manifest() -> Manifest? { animation.manifest() }

    func stateMachineLoad(id: String) -> Bool { animation.stateMachineLoad(id: id) }
    func stateMachineLoadData(_ data: String) -> Bool { animation.stateMachineLoadData(data) }
    func stateMachineStart() -> Bool { animation.stateMachineStart() }
    func stateMachineStop() -> Bool { animation.stateMachineStop() }
    func stateMachineFire(event: String) { animation.stateMachineFire(event: event) }
    func stateMachineSetNumericInput(key: String, value: Float) -> Bool {
        animation.stateMachineSetNumericInput(key: key, value: value)
    }
    func stateMachineSetStringInput(key: String, value: String) -> Bool {
        animation.stateMachineSetStringInput(key: key, value: value)
    }
    func stateMachineSetBooleanInput(key: String, value: Bool) -> Bool {
        animation.stateMachineSetBooleanInput(key: key, value: value)
    }
    func stateMachineGetNumericInput(key: String) -> Float {
        animation.stateMachineGetNumericInput(key: key)
    }
    func stateMachineGetStringInput(key: String) -> String {
        animation.stateMachineGetStringInput(key: key)
    }
    func stateMachineGetBooleanInput(key: String) -> Bool {
        animation.stateMachineGetBooleanInput(key: key)
    }
    func stateMachineGetInputs() -> [String: String] { animation.stateMachineGetInputs() }
    func stateMachineCurrentState() -> String { animation.stateMachineCurrentState() }
    func getStateMachine(_ id: String) -> String { animation.getStateMachine(id) }
}

// MARK: - WebGPU renderer

#if !targetEnvironment(macCatalyst)

final class DotLottieWebGPURenderer: DotLottieFlutterRenderer {
    static var isSupported: Bool { MTLCreateSystemDefaultDevice() != nil }

    let kind: DotLottieRendererKind = .webgpu
    let supportsBackgroundColor = false
    let emitsLoadEvent = true

    private let view: DotLottieWebGPUView
    private let source: DotLottieRendererSource

    private var player: DotLottiePlayer { view.player }

    init(config: AnimationConfig, source: DotLottieRendererSource) {
        self.source = source
        self.view = DotLottieWebGPUView(config: Self.coreConfig(from: config))
    }

    /// Mirrors `DotLottieAnimation`'s mapping so both renderers start from identical state.
    private static func coreConfig(from config: AnimationConfig) -> Config {
        Config(
            autoplay: config.autoplay ?? false,
            loopAnimation: config.loop ?? false,
            loopCount: UInt32(config.loopCount ?? 0),
            mode: config.mode ?? .forward,
            speed: config.speed ?? 1.0,
            useFrameInterpolation: config.useFrameInterpolation ?? false,
            segment: config.segments.map { [$0.0, $0.1] } ?? [],
            backgroundColor: 0,
            layout: config.layout ?? DotLottie.Layout(),
            marker: config.marker ?? "",
            themeId: config.themeId ?? "",
            stateMachineId: config.stateMachineId ?? "",
            animationId: config.animationId ?? ""
        )
    }

    func mount(in container: UIView) {
        view.frame = container.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(view)

        switch source {
        case .dotLottieData(let data): view.loadDotlottie(data: data)
        case .json(let json):          view.loadAnimationData(json)
        }
    }

    func unmount() {
        view.removeFromSuperview()
    }

    func subscribe(observer: Observer) { view.subscribe(observer: observer) }
    func unsubscribe(observer: Observer) { view.unsubscribe(observer: observer) }
    func stateMachineSubscribe(_ observer: StateMachineObserver) -> Bool {
        view.stateMachineSubscribe(observer: observer)
    }
    func stateMachineUnsubscribe(_ observer: StateMachineObserver) -> Bool {
        view.stateMachineUnsubscribe(observer: observer)
    }

    func play() -> Bool { view.play() }
    func pause() -> Bool { view.pause() }
    func stop() -> Bool { view.stop() }
    func isPlaying() -> Bool { view.isPlaying }
    func isPaused() -> Bool { view.isPaused }
    func isStopped() -> Bool { player.isStopped() }
    func isLoaded() -> Bool { view.isLoaded }

    func currentFrame() -> Float { player.currentFrame() }
    func totalFrames() -> Float { player.totalFrames() }
    func duration() -> Float { player.duration() }
    func loopCount() -> Int { Int(player.currentLoopCount()) }

    func currentProgress() -> Float {
        let total = player.totalFrames()
        guard total > 0 else { return 0 }
        return player.currentFrame() / total
    }

    func setFrame(frame: Float) -> Bool { player.setFrame(no: frame) }

    func setProgress(progress: Float) -> Bool {
        guard progress >= 0, progress <= 1 else { return false }
        let total = player.totalFrames()
        return player.setFrame(no: min(progress * total, max(total - 1, 0)))
    }

    func speed() -> Float { player.getSpeed() }
    func loop() -> Bool { player.getLoop() }
    func autoplay() -> Bool { player.getAutoplay() }
    func useFrameInterpolation() -> Bool { player.getUseFrameInterpolation() }

    func segments() -> (Float, Float) {
        let segment = player.getSegment() ?? []
        guard segment.count >= 2 else { return (0, 0) }
        return (segment[0], segment[1])
    }

    func mode() -> Mode { player.getMode() }
    func setSpeed(speed: Float) { _ = player.setSpeed(speed) }
    func setLoop(loop: Bool) { _ = player.setLoop(loop) }
    func setSegments(segments: (Float, Float)) {
        _ = player.setSegment(start: segments.0, end: segments.1)
    }
    func setMode(mode: Mode) { _ = player.setMode(mode) }
    func setFrameInterpolation(_ useFrameInterpolation: Bool) {
        _ = player.setUseFrameInterpolation(useFrameInterpolation)
    }

    /// Stored, but the opaque surface means it has no visible effect for now.
    func setBackgroundColor(hex: String) {
        guard let argb = DotLottieColor.argb(hex) else { return }
        _ = player.setBackgroundColor(argb)
    }

    func setLayout(layout: DotLottie.Layout) { _ = player.setLayout(layout) }

    /// No-op: the render target follows the view's bounds, with no CPU buffer to resize.
    func resize(width: Int, height: Int) {}

    func setTheme(_ themeId: String) -> Bool { player.setTheme(themeId: themeId) }
    func setThemeData(_ themeData: String) -> Bool { player.setThemeData(themeData: themeData) }
    func resetTheme() -> Bool { player.resetTheme() }
    func activeThemeId() -> String { player.activeThemeId() }
    func setSlots(_ slots: String) -> Bool { player.setSlotsStr(slots: slots) }

    func loadAnimationById(_ animationId: String) throws {
        guard player.loadAnimation(animationId: animationId) else {
            throw DotLottieRendererError(message: "Failed to load animation '\(animationId)'")
        }
    }

    func activeAnimationId() -> String { player.activeAnimationId() }
    func setMarker(marker: String) { _ = player.setMarker(marker) }
    func markers() -> [Marker] { player.markers() }
    func manifest() -> Manifest? { player.manifest() }

    func stateMachineLoad(id: String) -> Bool { view.stateMachineLoad(id: id) }
    func stateMachineLoadData(_ data: String) -> Bool { view.stateMachineLoadData(data) }
    func stateMachineStart() -> Bool { view.stateMachineStart() }
    func stateMachineStop() -> Bool { view.stateMachineStop() }
    func stateMachineFire(event: String) { _ = player.stateMachineFireEvent(event: event) }

    func stateMachineSetNumericInput(key: String, value: Float) -> Bool {
        player.stateMachineSetNumericInput(key: key, value: value)
    }
    func stateMachineSetStringInput(key: String, value: String) -> Bool {
        player.stateMachineSetStringInput(key: key, value: value)
    }
    func stateMachineSetBooleanInput(key: String, value: Bool) -> Bool {
        player.stateMachineSetBooleanInput(key: key, value: value)
    }
    func stateMachineGetNumericInput(key: String) -> Float {
        player.stateMachineGetNumericInput(key: key)
    }
    func stateMachineGetStringInput(key: String) -> String {
        player.stateMachineGetStringInput(key: key)
    }
    func stateMachineGetBooleanInput(key: String) -> Bool {
        player.stateMachineGetBooleanInput(key: key)
    }
    func stateMachineGetInputs() -> [String: String] { [:] }
    func stateMachineCurrentState() -> String { player.stateMachineCurrentState() }
    func getStateMachine(_ id: String) -> String { player.getStateMachine(stateMachineId: id) }
}

#endif

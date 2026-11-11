package com.lottiefiles.dotlottie_flutter

import android.graphics.PointF
import android.view.View
import com.dotlottie.dlplayer.Fit
import com.dotlottie.dlplayer.Manifest
import com.dotlottie.dlplayer.Marker
import com.dotlottie.dlplayer.Mode
import com.lottiefiles.dotlottie.core.ExperimentalDotLottieGLApi
import com.lottiefiles.dotlottie.core.model.Config
import com.lottiefiles.dotlottie.core.util.DotLottieEventListener
import com.lottiefiles.dotlottie.core.util.StateMachineEventListener
import com.lottiefiles.dotlottie.core.widget.DotLottieAnimation
import com.lottiefiles.dotlottie.core.widget.DotLottieGLAnimation

/**
 * Common interface for DotLottieAnimation (CPU) and DotLottieGLAnimation (OpenGL).
 * Both classes share the same public API — this interface lets the plugin code work
 * with either backend without duplication.
 */
interface DotLottiePlayerDelegate {
    val androidView: View

    // GL lifecycle — no-op for Standard, active for GL
    fun onResume()
    fun onPause()

    // Configuration
    fun load(config: Config)

    // Playback state
    val isPlaying: Boolean
    val isPaused: Boolean
    val isStopped: Boolean
    val isLoaded: Boolean
    val currentFrame: Float
    val totalFrames: Float
    val duration: Float
    val loopCount: UInt
    val speed: Float
    val loop: Boolean
    val autoplay: Boolean
    val useFrameInterpolation: Boolean
    val segment: Pair<Float, Float>
    val playMode: Mode
    val activeThemeId: String
    val activeAnimationId: String
    val markers: List<Marker>

    // Playback control
    fun play()
    fun pause()
    fun stop()
    fun requestRender()

    // Configuration setters
    fun setSpeed(speed: Float)
    fun setLoop(loop: Boolean)
    fun setFrame(frame: Float)
    fun setSegment(firstFrame: Float, lastFrame: Float)
    fun setPlayMode(mode: Mode)
    fun setUseFrameInterpolation(enable: Boolean)
    fun setBackgroundColor(color: Int)
    fun setMarker(marker: String)
    fun setLoopCount(loopCount: UInt)

    // Audio
    val audioVolume: Float
    fun setAudioVolume(volume: Float)

    // Theme / slots
    fun setTheme(themeId: String)
    fun setThemeData(themeData: String)
    fun resetTheme()
    fun setSlots(slots: String)
    fun setSlot(slotId: String, json: String): Boolean
    fun setColorSlot(slotId: String, color: Int): Boolean
    fun setScalarSlot(slotId: String, value: Float): Boolean
    fun setTextSlot(slotId: String, text: String): Boolean
    fun setVectorSlot(slotId: String, vector: PointF): Boolean
    fun setPositionSlot(slotId: String, position: PointF): Boolean
    fun setImageSlotSrc(slotId: String, src: String): Boolean
    fun setBezierPathSlot(
        slotId: String,
        vertices: List<PointF>,
        closed: Boolean,
        inTangents: List<PointF>?,
        outTangents: List<PointF>?
    ): Boolean
    fun clearSlot(slotId: String): Boolean
    fun clearSlots(): Boolean
    fun resetSlot(slotId: String): Boolean
    fun resetSlots(): Boolean
    fun getSlotIds(): List<String>
    fun getSlotType(slotId: String): String?
    fun getSlot(slotId: String): String?
    fun getSlots(): String

    // Animation
    fun loadAnimation(animationId: String)
    fun resize(width: Int, height: Int)
    fun setLayout(fit: Fit, alignX: Float, alignY: Float)
    fun manifest(): Manifest?

    // State machine
    fun stateMachineLoad(stateMachineId: String): Boolean
    fun stateMachineLoadData(data: String): Boolean
    fun stateMachineStart(): Boolean
    fun stateMachineStop(): Boolean
    fun stateMachineFireEvent(event: String)
    fun stateMachineSetNumericInput(key: String, value: Float): Boolean
    fun stateMachineSetStringInput(key: String, value: String): Boolean
    fun stateMachineSetBooleanInput(key: String, value: Boolean): Boolean
    fun stateMachineGetNumericInput(key: String): Float?
    fun stateMachineGetStringInput(key: String): String?
    fun stateMachineGetBooleanInput(key: String): Boolean?
    fun stateMachineCurrentState(): String?
    fun stateMachineStatus(): String?
    fun stateMachineSetSeed(seed: Long): Boolean
    fun stateMachineOverrideCurrentState(state: String, immediate: Boolean): Boolean
    fun stateMachineResetInput(key: String): Boolean
    fun stateMachineGetInputs(): Map<String, String>
    fun getStateMachine(stateMachineId: String): String?

    // Event listeners
    fun addEventListener(listener: DotLottieEventListener)
    fun addStateMachineEventListener(listener: StateMachineEventListener)
}

// ─────────────────────────────────────────────────────────────────────────────
// Standard (CPU) adapter
// ─────────────────────────────────────────────────────────────────────────────

class StandardPlayerAdapter(private val view: DotLottieAnimation) : DotLottiePlayerDelegate {
    override val androidView: View get() = view

    override fun onResume() {}
    override fun onPause() {}

    override fun load(config: Config) = view.load(config)

    override val isPlaying get() = view.isPlaying
    override val isPaused get() = view.isPaused
    override val isStopped get() = view.isStopped
    override val isLoaded get() = view.isLoaded
    override val currentFrame get() = view.currentFrame
    override val totalFrames get() = view.totalFrames
    override val duration get() = view.duration
    override val loopCount get() = view.loopCount
    override val speed get() = view.speed
    override val loop get() = view.loop
    override val autoplay get() = view.autoplay
    override val useFrameInterpolation get() = view.useFrameInterpolation
    override val segment get() = view.segment
    override val playMode get() = view.playMode
    override val activeThemeId get() = view.activeThemeId
    override val activeAnimationId get() = view.activeAnimationId
    override val markers get() = view.markers

    override fun play() = view.play()
    override fun pause() = view.pause()
    override fun stop() = view.stop()
    override fun requestRender() {} // View redraws automatically via Android draw system
    override fun setSpeed(speed: Float) = view.setSpeed(speed)
    override fun setLoop(loop: Boolean) = view.setLoop(loop)
    override fun setFrame(frame: Float) = view.setFrame(frame)
    override fun setSegment(firstFrame: Float, lastFrame: Float) = view.setSegment(firstFrame, lastFrame)
    override fun setPlayMode(mode: Mode) = view.setPlayMode(mode)
    override fun setUseFrameInterpolation(enable: Boolean) = view.setUseFrameInterpolation(enable)
    override fun setBackgroundColor(color: Int) = view.setBackgroundColor(color)
    override fun setMarker(marker: String) = view.setMarker(marker)
    override fun setLoopCount(loopCount: UInt) = view.setLoopCount(loopCount)
    override val audioVolume get() = view.audioVolume
    override fun setAudioVolume(volume: Float) = view.setAudioVolume(volume)
    override fun setTheme(themeId: String) = view.setTheme(themeId)
    override fun setThemeData(themeData: String) = view.setThemeData(themeData)
    override fun resetTheme() = view.resetTheme()
    override fun setSlots(slots: String) = view.setSlots(slots)
    override fun setSlot(slotId: String, json: String): Boolean = view.setSlot(slotId, json)
    override fun setColorSlot(slotId: String, color: Int): Boolean = view.setColorSlot(slotId, color)
    override fun setScalarSlot(slotId: String, value: Float): Boolean = view.setScalarSlot(slotId, value)
    override fun setTextSlot(slotId: String, text: String): Boolean = view.setTextSlot(slotId, text)
    override fun setVectorSlot(slotId: String, vector: PointF): Boolean = view.setVectorSlot(slotId, vector)
    override fun setPositionSlot(slotId: String, position: PointF): Boolean = view.setPositionSlot(slotId, position)
    override fun setImageSlotSrc(slotId: String, src: String): Boolean = view.setImageSlotSrc(slotId, src)
    override fun setBezierPathSlot(
        slotId: String,
        vertices: List<PointF>,
        closed: Boolean,
        inTangents: List<PointF>?,
        outTangents: List<PointF>?
    ): Boolean = view.setBezierPathSlot(slotId, vertices, closed, inTangents, outTangents)
    override fun clearSlot(slotId: String): Boolean = view.clearSlot(slotId)
    override fun clearSlots(): Boolean = view.clearSlots()
    override fun resetSlot(slotId: String): Boolean = view.resetSlot(slotId)
    override fun resetSlots(): Boolean = view.resetSlots()
    override fun getSlotIds(): List<String> = view.getSlotIds()
    override fun getSlotType(slotId: String): String? = view.getSlotType(slotId)
    override fun getSlot(slotId: String): String? = view.getSlot(slotId)
    override fun getSlots(): String = view.getSlots()
    override fun loadAnimation(animationId: String) = view.loadAnimation(animationId)
    override fun resize(width: Int, height: Int) = view.resize(width, height)
    override fun setLayout(fit: Fit, alignX: Float, alignY: Float) = view.setLayout(fit, Pair(alignX, alignY))
    override fun manifest(): Manifest? = view.manifest()

    override fun stateMachineLoad(stateMachineId: String): Boolean = view.stateMachineLoad(stateMachineId)
    override fun stateMachineLoadData(data: String): Boolean = view.stateMachineLoadData(data)
    override fun stateMachineStart(): Boolean = view.stateMachineStart()
    override fun stateMachineStop(): Boolean = view.stateMachineStop()
    override fun stateMachineFireEvent(event: String) = view.stateMachineFireEvent(event)
    override fun stateMachineSetNumericInput(key: String, value: Float): Boolean = view.stateMachineSetNumericInput(key, value)
    override fun stateMachineSetStringInput(key: String, value: String): Boolean = view.stateMachineSetStringInput(key, value)
    override fun stateMachineSetBooleanInput(key: String, value: Boolean): Boolean = view.stateMachineSetBooleanInput(key, value)
    override fun stateMachineGetNumericInput(key: String): Float? = view.stateMachineGetNumericInput(key)
    override fun stateMachineGetStringInput(key: String): String? = view.stateMachineGetStringInput(key)
    override fun stateMachineGetBooleanInput(key: String): Boolean? = view.stateMachineGetBooleanInput(key)
    override fun stateMachineCurrentState(): String? = view.stateMachineCurrentState()
    override fun stateMachineStatus(): String? = view.stateMachineStatus()
    override fun stateMachineSetSeed(seed: Long): Boolean = view.stateMachineSetSeed(seed)
    override fun stateMachineOverrideCurrentState(state: String, immediate: Boolean): Boolean = view.stateMachineOverrideCurrentState(state, immediate)
    override fun stateMachineResetInput(key: String): Boolean = view.stateMachineResetInput(key)
    override fun stateMachineGetInputs(): Map<String, String> = view.stateMachineGetInputs()
    override fun getStateMachine(stateMachineId: String): String? = view.getStateMachine(stateMachineId)

    override fun addEventListener(listener: DotLottieEventListener) = view.addEventListener(listener)
    override fun addStateMachineEventListener(listener: StateMachineEventListener) = view.addStateMachineEventListener(listener)
}

// ─────────────────────────────────────────────────────────────────────────────
// GL (OpenGL) adapter — @OptIn confines the experimental API to this class only
// ─────────────────────────────────────────────────────────────────────────────

@OptIn(ExperimentalDotLottieGLApi::class)
class GLPlayerAdapter(private val view: DotLottieGLAnimation) : DotLottiePlayerDelegate {
    override val androidView: View get() = view

    override fun onResume() = view.onResume()
    override fun onPause() = view.onPause()

    override fun load(config: Config) = view.load(config)

    override val isPlaying get() = view.isPlaying
    override val isPaused get() = view.isPaused
    override val isStopped get() = view.isStopped
    override val isLoaded get() = view.isLoaded
    override val currentFrame get() = view.currentFrame
    override val totalFrames get() = view.totalFrames
    override val duration get() = view.duration
    override val loopCount get() = view.loopCount
    override val speed get() = view.speed
    override val loop get() = view.loop
    override val autoplay get() = view.autoplay
    override val useFrameInterpolation get() = view.useFrameInterpolation
    override val segment get() = view.segment
    override val playMode get() = view.playMode
    override val activeThemeId get() = view.activeThemeId
    override val activeAnimationId get() = view.activeAnimationId
    override val markers get() = view.markers

    override fun play() = view.play()
    override fun pause() = view.pause()
    override fun stop() = view.stop()
    override fun requestRender() = view.requestRender()
    override fun setSpeed(speed: Float) = view.setSpeed(speed)
    override fun setLoop(loop: Boolean) = view.setLoop(loop)
    override fun setFrame(frame: Float) = view.setFrame(frame)
    override fun setSegment(firstFrame: Float, lastFrame: Float) = view.setSegment(firstFrame, lastFrame)
    override fun setPlayMode(mode: Mode) = view.setPlayMode(mode)
    override fun setUseFrameInterpolation(enable: Boolean) = view.setUseFrameInterpolation(enable)
    override fun setBackgroundColor(color: Int) = view.setBackgroundColor(color)
    override fun setMarker(marker: String) = view.setMarker(marker)
    override fun setLoopCount(loopCount: UInt) = view.setLoopCount(loopCount)
    override val audioVolume get() = view.audioVolume
    override fun setAudioVolume(volume: Float) = view.setAudioVolume(volume)
    override fun setTheme(themeId: String) = view.setTheme(themeId)
    override fun setThemeData(themeData: String) = view.setThemeData(themeData)
    override fun resetTheme() = view.resetTheme()
    override fun setSlots(slots: String) = view.setSlots(slots)
    override fun setSlot(slotId: String, json: String): Boolean = view.setSlot(slotId, json)
    override fun setColorSlot(slotId: String, color: Int): Boolean = view.setColorSlot(slotId, color)
    override fun setScalarSlot(slotId: String, value: Float): Boolean = view.setScalarSlot(slotId, value)
    override fun setTextSlot(slotId: String, text: String): Boolean = view.setTextSlot(slotId, text)
    override fun setVectorSlot(slotId: String, vector: PointF): Boolean = view.setVectorSlot(slotId, vector)
    override fun setPositionSlot(slotId: String, position: PointF): Boolean = view.setPositionSlot(slotId, position)
    override fun setImageSlotSrc(slotId: String, src: String): Boolean = view.setImageSlotSrc(slotId, src)
    override fun setBezierPathSlot(
        slotId: String,
        vertices: List<PointF>,
        closed: Boolean,
        inTangents: List<PointF>?,
        outTangents: List<PointF>?
    ): Boolean = view.setBezierPathSlot(slotId, vertices, closed, inTangents, outTangents)
    override fun clearSlot(slotId: String): Boolean = view.clearSlot(slotId)
    override fun clearSlots(): Boolean = view.clearSlots()
    override fun resetSlot(slotId: String): Boolean = view.resetSlot(slotId)
    override fun resetSlots(): Boolean = view.resetSlots()
    override fun getSlotIds(): List<String> = view.getSlotIds()
    override fun getSlotType(slotId: String): String? = view.getSlotType(slotId)
    override fun getSlot(slotId: String): String? = view.getSlot(slotId)
    override fun getSlots(): String = view.getSlots()
    override fun loadAnimation(animationId: String) = view.loadAnimation(animationId)
    override fun resize(width: Int, height: Int) = view.resize(width, height)
    override fun setLayout(fit: Fit, alignX: Float, alignY: Float) = view.setLayout(fit, Pair(alignX, alignY))
    override fun manifest(): Manifest? = view.manifest()

    override fun stateMachineLoad(stateMachineId: String): Boolean = view.stateMachineLoad(stateMachineId)
    override fun stateMachineLoadData(data: String): Boolean = view.stateMachineLoadData(data)
    override fun stateMachineStart(): Boolean = view.stateMachineStart()
    override fun stateMachineStop(): Boolean = view.stateMachineStop()
    override fun stateMachineFireEvent(event: String) = view.stateMachineFireEvent(event)
    override fun stateMachineSetNumericInput(key: String, value: Float): Boolean = view.stateMachineSetNumericInput(key, value)
    override fun stateMachineSetStringInput(key: String, value: String): Boolean = view.stateMachineSetStringInput(key, value)
    override fun stateMachineSetBooleanInput(key: String, value: Boolean): Boolean = view.stateMachineSetBooleanInput(key, value)
    override fun stateMachineGetNumericInput(key: String): Float? = view.stateMachineGetNumericInput(key)
    override fun stateMachineGetStringInput(key: String): String? = view.stateMachineGetStringInput(key)
    override fun stateMachineGetBooleanInput(key: String): Boolean? = view.stateMachineGetBooleanInput(key)
    override fun stateMachineCurrentState(): String? = view.stateMachineCurrentState()
    override fun stateMachineStatus(): String? = view.stateMachineStatus()
    override fun stateMachineSetSeed(seed: Long): Boolean = view.stateMachineSetSeed(seed)
    override fun stateMachineOverrideCurrentState(state: String, immediate: Boolean): Boolean = view.stateMachineOverrideCurrentState(state, immediate)
    override fun stateMachineResetInput(key: String): Boolean = view.stateMachineResetInput(key)
    override fun stateMachineGetInputs(): Map<String, String> = view.stateMachineGetInputs()
    override fun getStateMachine(stateMachineId: String): String? = view.getStateMachine(stateMachineId)

    override fun addEventListener(listener: DotLottieEventListener) = view.addEventListener(listener)
    override fun addStateMachineEventListener(listener: StateMachineEventListener) = view.addStateMachineEventListener(listener)
}

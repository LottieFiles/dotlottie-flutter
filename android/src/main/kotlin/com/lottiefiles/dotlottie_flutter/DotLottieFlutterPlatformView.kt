package com.lottiefiles.dotlottie_flutter

import android.content.Context
import android.graphics.Color
import android.util.Log
import com.dotlottie.dlplayer.Mode
import com.lottiefiles.dotlottie.core.model.Config
import com.lottiefiles.dotlottie.core.util.DotLottieEventListener
import com.lottiefiles.dotlottie.core.util.StateMachineEventListener
import com.lottiefiles.dotlottie.core.util.DotLottieSource
import com.lottiefiles.dotlottie.core.widget.DotLottieAnimation
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import android.os.Looper
import android.os.Handler

class DotLottiePlatformView(
    context: Context,
    private val viewId: Int,
    creationParams: Map<String, Any>?
) : PlatformView {
    private val dotLottieView: DotLottieAnimation = DotLottieAnimation(context)
    private val methodChannel: MethodChannel
    private var isDisposed = false
    // Register event listeners with Handler for main thread
    val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

    init {
        val layoutParams = android.view.ViewGroup.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.ViewGroup.LayoutParams.MATCH_PARENT
        )
        dotLottieView.layoutParams = layoutParams

        methodChannel = MethodChannel(DotLottieFlutterPlugin.binaryMessenger, "dotlottie_view_$viewId")

        // Set up method call handler
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        // Load animation from creation params
        creationParams?.let { params ->
            setupAnimation(params)
        }
    }

    private fun invokeOnMainThread(method: String, arguments: Any? = null) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            // Already on main thread
            methodChannel.invokeMethod(method, arguments)
        } else {
            // On background thread, post to main
            mainHandler.post {
                methodChannel.invokeMethod(method, arguments)
            }
        }
    }

    private fun setupAnimation(params: Map<String, Any>) {
        val sourceType = params["sourceType"] as? String ?: return
        val autoplay = params["autoplay"] as? Boolean ?: false
        val loop = params["loop"] as? Boolean ?: false
        val speed = (params["speed"] as? Number)?.toFloat() ?: 1f
        val mode = params["mode"] as? String ?: "forward"
        val useFrameInterpolation = params["useFrameInterpolation"] as? Boolean ?: false
        val backgroundColor = params["backgroundColor"] as? String
        val stateMachineId = params["stateMachineId"] as? String ?: ""
    
        
        dotLottieView.addEventListener(
            object : DotLottieEventListener {
                override fun onLoad() {
                    mainHandler.postDelayed({
                        invokeOnMainThread("onLoad")
                    }, 50)
                }
    
                override fun onLoadError(error: Throwable) {
                        invokeOnMainThread("onLoadError")
                }
    
                override fun onPlay() {
                    mainHandler.post {
                        invokeOnMainThread("onPlay")
                    }
                }
    
                override fun onPause() {
                        invokeOnMainThread("onPause")
                }
    
                override fun onStop() {
                        invokeOnMainThread("onStop")
                }
    
                override fun onComplete() {
                        invokeOnMainThread("onComplete")
                }
    
                override fun onFrame(frame: Float) {
                        invokeOnMainThread("onFrame", frame)
                }
    
                override fun onLoop(loopCount: Int) {
                        invokeOnMainThread("onLoop", loopCount)
                }
    
                override fun onFreeze() {}
                override fun onUnFreeze() {}
                override fun onDestroy() {}
            }
        )
    
        // State machine listeners with main thread handler
        dotLottieView.addStateMachineEventListener(
            object : StateMachineEventListener {
                override fun onStart() {
                    mainHandler.post {
                        methodChannel.invokeMethod("stateMachineOnStart", null)
                    }
                }
    
                override fun onStop() {
                    mainHandler.post {
                        methodChannel.invokeMethod("stateMachineOnStop", null)
                    }
                }
    
                override fun onStateEntered(enteringState: String) {
                    mainHandler.post {
                        methodChannel.invokeMethod("stateMachineOnStateEntered", enteringState)
                    }
                }
    
                override fun onStateExit(leavingState: String) {
                    mainHandler.post {
                        methodChannel.invokeMethod("stateMachineOnStateExit", leavingState)
                    }
                }
    
                override fun onTransition(previousState: String, newState: String) {
                    mainHandler.post {
                        val args = mapOf("previousState" to previousState, "newState" to newState)
                        methodChannel.invokeMethod("stateMachineOnTransition", args)
                    }
                }
    
                override fun onNumericInputValueChange(inputName: String, oldValue: Float, newValue: Float) {
                    mainHandler.post {
                        val args = mapOf("inputName" to inputName, "oldValue" to oldValue, "newValue" to newValue)
                        methodChannel.invokeMethod("stateMachineOnNumericInputValueChange", args)
                    }
                }
    
                override fun onStringInputValueChange(inputName: String, oldValue: String, newValue: String) {
                    mainHandler.post {
                        val args = mapOf("inputName" to inputName, "oldValue" to oldValue, "newValue" to newValue)
                        methodChannel.invokeMethod("stateMachineOnStringInputValueChange", args)
                    }
                }
    
                override fun onBooleanInputValueChange(inputName: String, oldValue: Boolean, newValue: Boolean) {
                    mainHandler.post {
                        val args = mapOf("inputName" to inputName, "oldValue" to oldValue, "newValue" to newValue)
                        methodChannel.invokeMethod("stateMachineOnBooleanInputValueChange", args)
                    }
                }
    
                override fun onCustomEvent(message: String) {
                    mainHandler.post {
                        methodChannel.invokeMethod("stateMachineOnCustomEvent", message)
                    }
                }
    
                override fun onError(message: String) {
                    mainHandler.post {
                        methodChannel.invokeMethod("stateMachineOnError", message)
                    }
                }
    
                override fun onInputFired(inputName: String) {
                    mainHandler.post {
                        val args = mapOf("inputName" to inputName)
                        methodChannel.invokeMethod("stateMachineOnInputFired", args)
                    }
                }
            }
        )
    
        // Create source
        val dotLottieSource = when (sourceType) {
            "url" -> {
                val source = params["source"] as? String ?: return
                DotLottieSource.Url(source)
            }
            "data" -> {
                val data = params["source"] as? ByteArray ?: return
                DotLottieSource.Data(data)
            }
            "json" -> {
                val source = params["source"] as? String ?: return
                DotLottieSource.Json(source)
            }
            else -> return
        }
    
        // Wait for view to have dimensions before loading
        dotLottieView.post {
            try {
                val playMode = when (mode.lowercase()) {
                    "forward" -> Mode.FORWARD
                    "reverse" -> Mode.REVERSE
                    "bounce" -> Mode.BOUNCE
                    "reverse-bounce" -> Mode.REVERSE_BOUNCE
                    else -> Mode.FORWARD
                }
    
                val configBuilder = Config.Builder()
                    .autoplay(autoplay)
                    .loop(loop)
                    .speed(speed)
                    .source(dotLottieSource)
                    .playMode(playMode)
                    .useFrameInterpolation(useFrameInterpolation)
                    .stateMachineId(stateMachineId)
    
                backgroundColor?.let {
                    try {
                        val color = parseColor(it)
                        dotLottieView.setBackgroundColor(color)
                    } catch (e: Exception) {
                        Log.e("DotLottie", "Error parsing background color", e)
                    }
                }
    
                val config = configBuilder.build()
                dotLottieView.load(config)
            } catch (e: Exception) {
                Log.e("DotLottie", "💥 Exception during load: ${e.message}", e)
                mainHandler.post {
                    methodChannel.invokeMethod("onLoadError", null)
                }
            }
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (isDisposed) {
            result.error("DISPOSED", "View has been disposed", null)
            return
        }

        try {
            when (call.method) {
                "play" -> {
                    dotLottieView.play()
                    result.success(true)
                }

                "pause" -> {
                    dotLottieView.pause()
                    result.success(true)
                }

                "stop" -> {
                    dotLottieView.stop()
                    result.success(true)
                }

                "isPlaying" -> {
                    result.success(dotLottieView.isPlaying)
                }

                "isPaused" -> {
                    result.success(dotLottieView.isPaused)
                }

                "isStopped" -> {
                    result.success(dotLottieView.isStopped)
                }

                "isLoaded" -> {
                    result.success(dotLottieView.isLoaded)
                }

                "currentFrame" -> {
                    result.success(dotLottieView.currentFrame.toDouble())
                }

                "totalFrames" -> {
                    result.success(dotLottieView.totalFrames.toDouble())
                }

                "currentProgress" -> {
                    val totalFrames = dotLottieView.totalFrames
                    val progress = if (totalFrames > 0f) {
                        dotLottieView.currentFrame / totalFrames
                    } else {
                        0f
                    }
                    result.success(progress.toDouble())
                }

                "duration" -> {
                    result.success(dotLottieView.duration.toDouble())
                }

                "loopCount" -> {
                    result.success(dotLottieView.loopCount.toInt())
                }

                "speed" -> {
                    result.success(dotLottieView.speed.toDouble())
                }

                "loop" -> {
                    result.success(dotLottieView.loop)
                }

                "autoplay" -> {
                    result.success(dotLottieView.autoplay)
                }

                "useFrameInterpolation" -> {
                    result.success(dotLottieView.useFrameInterpolation)
                }

                "segments" -> {
                    val segment = dotLottieView.segment
                    result.success(listOf(segment.first.toDouble(), segment.second.toDouble()))
                }

                "mode" -> {
                    val mode = when (dotLottieView.playMode) {
                        Mode.FORWARD -> "forward"
                        Mode.REVERSE -> "reverse"
                        Mode.BOUNCE -> "bounce"
                        Mode.REVERSE_BOUNCE -> "reverseBounce"
                        else -> "forward"
                    }
                    result.success(mode)
                }

                "setSpeed" -> {
                    val speed = call.argument<Double>("speed")?.toFloat()
                    if (speed != null) {
                        dotLottieView.setSpeed(speed)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid speed argument", null)
                    }
                }

                "setLoop" -> {
                    val loop = call.argument<Boolean>("loop")
                    if (loop != null) {
                        dotLottieView.setLoop(loop)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid loop argument", null)
                    }
                }

                "setFrame" -> {
                    val frame = call.argument<Double>("frame")?.toFloat()
                    if (frame != null) {
                        dotLottieView.setFrame(frame)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Invalid frame argument", null)
                    }
                }

                "setProgress" -> {
                    val progress = call.argument<Double>("progress")?.toFloat()
                    if (progress != null) {
                        val totalFrames = dotLottieView.totalFrames
                        val frame = progress * totalFrames
                        dotLottieView.setFrame(frame)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Invalid progress argument", null)
                    }
                }

                "setSegments" -> {
                    val start = call.argument<Double>("start")?.toFloat()
                    val end = call.argument<Double>("end")?.toFloat()
                    if (start != null && end != null) {
                        dotLottieView.setSegment(start, end)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid segments arguments", null)
                    }
                }

                "setMode" -> {
                    val modeString = call.argument<String>("mode")
                    if (modeString != null) {
                        val mode = when (modeString) {
                            "forward" -> Mode.FORWARD
                            "reverse" -> Mode.REVERSE
                            "bounce" -> Mode.BOUNCE
                            "reverseBounce" -> Mode.REVERSE_BOUNCE
                            else -> Mode.FORWARD
                        }
                        dotLottieView.setPlayMode(mode)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid mode argument", null)
                    }
                }

                "setFrameInterpolation" -> {
                    val useFrameInterpolation = call.argument<Boolean>("useFrameInterpolation")
                    if (useFrameInterpolation != null) {
                        dotLottieView.setUseFrameInterpolation(useFrameInterpolation)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid frameInterpolation argument", null)
                    }
                }

                "setBackgroundColor" -> {
                    val colorString = call.argument<String>("color")
                    if (colorString != null) {
                        try {
                            val color = parseColor(colorString)
                            dotLottieView.setBackgroundColor(color)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("INVALID_COLOR", "Invalid color format", e.message)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid backgroundColor argument", null)
                    }
                }

                "setTheme" -> {
                    val themeId = call.argument<String>("themeId")
                    if (themeId != null) {
                        val success = dotLottieView.setTheme(themeId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "Invalid theme argument", null)
                    }
                }

                "setThemeData" -> {
                    val themeData = call.argument<String>("themeData")
                    if (themeData != null) {
                        try {
                            val success = dotLottieView.setThemeData(themeData)
                            result.success(success)
                        } catch (e: Exception) {
                            Log.w("🔴 DotLottie", "setThemeData not available", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid themeData argument", null)
                    }
                }

                "resetTheme" -> {
                    try {
                        dotLottieView.resetTheme()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.w("🔴 DotLottie", "resetTheme not available", e)
                        result.success(false)
                    }
                }

                "activeThemeId" -> {
                    try {
                        result.success(dotLottieView.activeThemeId)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }

                "loadAnimation" -> {
                    val animationId = call.argument<String>("animationId")
                    if (animationId != null) {
                        dotLottieView.loadAnimation(animationId)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid animationId argument", null)
                    }
                }

                "activeAnimationId" -> {
                    try {
                        result.success(dotLottieView.activeAnimationId)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }

                "setMarker" -> {
                    val marker = call.argument<String>("marker")
                    if (marker != null) {
                        dotLottieView.setMarker(marker)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid marker argument", null)
                    }
                }

                "markers" -> {
                    try {
                        val markers = dotLottieView.markers
                        val markerList = markers.map { marker ->
                            mapOf<String, Any>(
                                "name" to marker.name,
                                "time" to marker.time,
                                "duration" to marker.duration
                            )
                        }
                        result.success(markerList)
                    } catch (e: Exception) {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }

                "setSlots" -> {
                    val slots = call.argument<String>("slots")
                    if (slots != null) {
                        try {
                            val success = dotLottieView.setSlots(slots)
                            result.success(success)
                        } catch (e: Exception) {
                            Log.w("🔴 DotLottie", "setSlots not available", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid slots argument", null)
                    }
                }

                "resize" -> {
                    val width = call.argument<Int>("width")
                    val height = call.argument<Int>("height")
                    if (width != null && height != null) {
                        try {
                            dotLottieView.resize(width, height)
                            result.success(null)
                        } catch (e: Exception) {
                            Log.w("🔴 DotLottie", "resize not available", e)
                            result.success(null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid resize arguments", null)
                    }
                }

                "getLayerBounds" -> {
                    // Not available in Android DotLottie widget API
                    result.success(null)
                }

                "stateMachineLoad" -> {
                    val stateMachineId = call.argument<String>("stateMachineId")
                    if (stateMachineId != null) {
                        try {
                            val success = dotLottieView.stateMachineLoad(stateMachineId)
                            result.success(success)
                        } catch (e: Exception) {
                            Log.w("🔴 DotLottie", "loadStateMachine not available", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid stateMachineId argument", null)
                    }
                }

                "stateMachineLoadData" -> {
                    result.success(false)
                }

                "stateMachineStart" -> {
                    try {
                        val success = dotLottieView.stateMachineStart()
                        result.success(success)
                    } catch (e: Exception) {
                        Log.w("🔴 DotLottie", "startStateMachine not available", e)
                        result.success(false)
                    }
                }

                "stateMachineStop" -> {
                    try {
                        val success = dotLottieView.stateMachineStop()
                        result.success(success)
                    } catch (e: Exception) {
                        Log.w("🔴 DotLottie", "stopStateMachine not available", e)
                        result.success(false)
                    }
                }

                "stateMachineFire" -> {
                    val event = call.argument<String>("event")
                    if (event != null) {
                        try {
                            dotLottieView.stateMachineFireEvent(event)
                            result.success(null)
                        } catch (e: Exception) {
                            Log.w("🔴 DotLottie", "postStateMachineEvent not available", e)
                            result.success(null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid event argument", null)
                    }
                }

                "stateMachineSetNumericInput" -> {
                    val key = call.argument<String>("key")
                        ?: return result.error("INVALID_ARGS", "Invalid stateMachineSetNumericInput argument", null)
                    val value = call.argument<Double>("value")
                        ?: return result.error("INVALID_ARGS", "Invalid or missing value argument", null)
                    try {
                        val success = dotLottieView.stateMachineSetNumericInput(key, value.toFloat())
                        result.success(success)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stateMachineSetStringInput" -> {
                    val key = call.argument<String>("key")
                        ?: return result.error("INVALID_ARGS", "Invalid stateMachineSetStringInput argument", null)
                    val value = call.argument<String>("value")
                        ?: return result.error("INVALID_ARGS", "Invalid or missing value argument", null)
                    try {
                        val success = dotLottieView.stateMachineSetStringInput(key, value)
                        result.success(success)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stateMachineSetBooleanInput" -> {
                    val key = call.argument<String>("key")
                        ?: return result.error("INVALID_ARGS", "Invalid stateMachineSetBooleanInput argument", null)
                    val value = call.argument<Boolean>("value")
                        ?: return result.error("INVALID_ARGS", "Invalid or missing value argument", null)
                    try {
                        val success = dotLottieView.stateMachineSetBooleanInput(key, value)
                        result.success(success)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stateMachineGetNumericInput" -> {
                    val key = call.argument<String>("key")
                        ?: return result.error("INVALID_ARGS", "Invalid stateMachineGetNumericInput argument", null)
                    try {
                        val number = dotLottieView.stateMachineGetNumericInput(key)
                        result.success(number)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "stateMachineGetStringInput" -> {
                    val key = call.argument<String>("key")
                        ?: return result.error("INVALID_ARGS", "Invalid stateMachineGetStringInput argument", null)
                    try {
                        val value = dotLottieView.stateMachineGetStringInput(key)
                        result.success(value)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "stateMachineGetBooleanInput" -> {
                    val key = call.argument<String>("key")
                        ?: return result.error("INVALID_ARGS", "Invalid stateMachineGetBooleanInput argument", null)
                    try {
                        val boolValue = dotLottieView.stateMachineGetBooleanInput(key)
                        result.success(boolValue)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "stateMachineGetInputs" -> result.success(emptyMap<String, String>())
                "getStateMachine" -> result.success(null)
                
                "stateMachineCurrentState" -> {
                    try {
                        result.success(dotLottieView.stateMachineCurrentState())
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                // Manifest method
                "manifest" -> {
                    try {
                        val manifest = dotLottieView.manifest()
                        if (manifest != null) {
                            // Convert Manifest to dictionary
                            val manifestDict = mutableMapOf<String, Any?>()

                            manifestDict["version"] = manifest.version
                            manifestDict["generator"] = manifest.generator

                            // Convert ManifestInitial
                            manifest.initial?.let { initial ->
                                val initialDict = mutableMapOf<String, Any?>()
                                initialDict["animation"] = initial.animation
                                initialDict["stateMachine"] = initial.stateMachine
                                manifestDict["initial"] = initialDict
                            }

                            // Convert ManifestAnimation array
                            manifestDict["animations"] = manifest.animations.map { animation ->
                                mapOf<String, Any?>(
                                    "id" to animation.id,
                                    "name" to animation.name,
                                    "initialTheme" to animation.initialTheme,
                                    "themes" to animation.themes,
                                    "background" to animation.background
                                )
                            }

                            // Convert ManifestTheme array
                            manifest.themes?.let { themes ->
                                manifestDict["themes"] = themes.map { theme ->
                                    mapOf<String, Any?>(
                                        "id" to theme.id,
                                        "name" to theme.name
                                    )
                                }
                            }

                            // Convert ManifestStateMachine array
                            manifest.stateMachines?.let { stateMachines ->
                                manifestDict["stateMachines"] = stateMachines.map { stateMachine ->
                                    mapOf<String, Any?>(
                                        "id" to stateMachine.id,
                                        "name" to stateMachine.name
                                    )
                                }
                            }

                            result.success(manifestDict)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        Log.e("🔴 DotLottie", "Error getting manifest", e)
                        result.success(null)
                    }
                }

                "dispose" -> {
                    dispose()
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("ERROR", "Error handling method: ${call.method}", e.message)
        }
    }

    private fun parseColor(colorString: String): Int {
        var hex = colorString.trim().replace("#", "")

        return when (hex.length) {
            6 -> {
                // RGB format
                Color.parseColor("#$hex")
            }
            8 -> {
                // ARGB format
                Color.parseColor("#$hex")
            }
            else -> {
                throw IllegalArgumentException("Invalid color format: $colorString")
            }
        }
    }

    override fun getView(): DotLottieAnimation {
        return dotLottieView
    }

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true

        dotLottieView.stop()
        DotLottieFlutterPlugin.platformViews.remove(viewId)
    }
}
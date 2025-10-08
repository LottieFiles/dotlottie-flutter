package com.lottiefiles.dotlottie_flutter

import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.lottiefiles.dotlottie.core.model.Config
import com.dotlottie.dlplayer.Mode
import com.lottiefiles.dotlottie.core.util.DotLottieSource
import com.lottiefiles.dotlottie.core.widget.DotLottieAnimation
import com.lottiefiles.dotlottie.core.util.DotLottieEventListener
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


/** DotlottieFlutterPlugin */
//class DotlottieFlutterPlugin :
//    FlutterPlugin,
//    MethodCallHandler,
//    ActivityAware {  // Add ActivityAware
//
//    private lateinit var channel: MethodChannel
//    private var player: DotLottieAnimation? = null
//    private var activity: Activity? = null  // Change from context to activity
//
//    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//        Log.d("🔴 DotLottie", "Plugin attached to engine")
//
//        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dotlottie_flutter")
//        channel.setMethodCallHandler(this)
//
//        // Register platform view factory for rendering the animation
//        flutterPluginBinding
//            .platformViewRegistry
//            .registerViewFactory(
//                "dotlottie_view",
//                DotLottieViewFactory(flutterPluginBinding.binaryMessenger)
//            )
//    }
//
//    // ActivityAware implementation
//    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
//        Log.d("🔴 DotLottie", "Attached to activity")
//        activity = binding.activity
//    }
//
//    override fun onDetachedFromActivityForConfigChanges() {
//        activity = null
//    }
//
//    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
//        activity = binding.activity
//    }
//
//    override fun onDetachedFromActivity() {
//        activity = null
//    }
//
//    override fun onMethodCall(
//        call: MethodCall,
//        result: Result
//    ) {
//        Log.d("🔴 DotLottie", "Method called: ${call.method}")
//
//        when (call.method) {
//            "getPlatformVersion" -> {
//                result.success("Android ${android.os.Build.VERSION.RELEASE}")
//            }
//            "createPlayer" -> {
//                Log.d("🔴 DotLottie", "Creating player")
//
//                if (activity == null) {
//                    Log.e("🔴 DotLottie", "Activity is null!")
//                    result.error("NO_ACTIVITY", "Activity not available", null)
//                    return
//                }
//
//                player = DotLottieAnimation(activity!!)
//
//                // Set a layout size so the view doesn't complain
//                val layoutParams = android.view.ViewGroup.LayoutParams(
//                    android.view.ViewGroup.LayoutParams.MATCH_PARENT,
//                    android.view.ViewGroup.LayoutParams.MATCH_PARENT
//                )
//                player?.layoutParams = layoutParams
//                player?.measure(
//                    android.view.View.MeasureSpec.makeMeasureSpec(300, android.view.View.MeasureSpec.EXACTLY),
//                    android.view.View.MeasureSpec.makeMeasureSpec(300, android.view.View.MeasureSpec.EXACTLY)
//                )
//                player?.layout(0, 0, 300, 300)
//
//                // Setup event listeners
//                player?.addEventListener(object : DotLottieEventListener {
//                    override fun onLoad() {
//                        Log.d("🔴 DotLottie", "✅ Native onLoad triggered!")
//                        channel.invokeMethod("onLoad", null)
//                    }
//
//                    override fun onPlay() {
//                        Log.d("🔴 DotLottie", "✅ Native onPlay triggered!")
//                        channel.invokeMethod("onPlay", null)
//                    }
//
//                    override fun onPause() {
//                        Log.d("🔴 DotLottie", "✅ Native onPause triggered!")
//                        channel.invokeMethod("onPause", null)
//                    }
//
//                    override fun onStop() {
//                        Log.d("🔴 DotLottie", "✅ Native onStop triggered!")
//                        channel.invokeMethod("onStop", null)
//                    }
//
//                    override fun onComplete() {
//                        Log.d("🔴 DotLottie", "✅ Native onComplete triggered!")
//                        channel.invokeMethod("onComplete", null)
//                    }
//
//                    override fun onFrame(frame: Float) {
//                        channel.invokeMethod("onFrame", mapOf("frame" to frame.toDouble()))
//                    }
//
//                    override fun onLoop(loopCount: Int) {
//                        Log.d("🔴 DotLottie", "✅ Native onLoop triggered!")
//                        channel.invokeMethod("onLoop", null)
//                    }
//
//                    override fun onLoadError(error: Throwable) {
//                        Log.d("🔴 DotLottie", "onLoadError ${error.localizedMessage}")
////                        channel.invokeMethod("onLoadError", null)
//                    }
//
//
//                    override fun onFreeze() {}
//                    override fun onUnFreeze() {}
//                    override fun onDestroy() {}
//                })
//
//                Log.d("🔴 DotLottie", "Player created successfully")
//                result.success(null)
//            }
//            "loadAnimation" -> {
//                Log.d("🔴 DotLottie", "loadAnimation called")
//                val sourceType = call.argument<String>("sourceType")
//                val source = call.argument<String>("source")
//                val autoplay = call.argument<Boolean>("autoplay") ?: true
//                val loop = call.argument<Boolean>("loop") ?: true
//                val speed = call.argument<Double>("speed")?.toFloat() ?: 1f
//
//                Log.d("🔴 DotLottie", "Source: $source, Type: $sourceType, Autoplay: $autoplay")
//
//                if (player == null) {
//                    Log.e("🔴 DotLottie", "Player is null!")
//                    result.error("NO_PLAYER", "Player not created", null)
//                    return
//                }
//
//                val dotLottieSource = when (sourceType) {
//                    "url" -> DotLottieSource.Url(source!!)
//                    "asset" -> DotLottieSource.Asset(source!!)
//                    "json" -> DotLottieSource.Json(source!!)
//                    else -> {
//                        Log.e("🔴 DotLottie", "Invalid source type: $sourceType")
//                        result.error("INVALID_SOURCE", "Invalid source type", null)
//                        return
//                    }
//                }
//
//                val config = Config.Builder()
//                    .autoplay(autoplay)
//                    .loop(loop)
//                    .speed(speed)
//                    .source(dotLottieSource)
//                    .playMode(Mode.FORWARD)
//                    .build()
//
//                Log.d("🔴 DotLottie", "About to load animation...")
//                player?.load(config)
//                Log.d("🔴 DotLottie", "Animation load() called")
//                result.success(null)
//            }
//            "play" -> {
//                player?.play()
//                result.success(null)
//            }
//            "pause" -> {
//                player?.pause()
//                result.success(null)
//            }
//            "stop" -> {
//                player?.stop()
//                result.success(null)
//            }
//            "setSpeed" -> {
//                val speed = call.argument<Double>("speed")?.toFloat()
//                if (speed != null) {
//                    player?.setSpeed(speed)
//                }
//                result.success(null)
//            }
//            "setLoop" -> {
//                val loop = call.argument<Boolean>("loop") ?: true
//                player?.setLoop(loop)
//                result.success(null)
//            }
//            "getCurrentFrame" -> {
//                result.success(player?.currentFrame?.toDouble())
//            }
//            "getTotalFrames" -> {
//                result.success(player?.totalFrames?.toDouble())
//            }
//            "isPlaying" -> {
//                result.success(player?.isPlaying)
//            }
//            "isPaused" -> {
//                result.success(player?.isPaused)
//            }
//            else -> {
//                result.notImplemented()
//            }
//        }
//    }
//
//    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//        channel.setMethodCallHandler(null)
//        player = null
//        activity = null
//    }
//}
//
//// Platform View for rendering the animation
//class DotLottieViewFactory(
//    private val messenger: io.flutter.plugin.common.BinaryMessenger
//) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
//
//    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
//        return DotLottiePlatformView(context, viewId, args as? Map<String, Any>)
//    }
//}
//
//class DotLottiePlatformView(
//    context: Context,
//    id: Int,
//    creationParams: Map<String, Any>?
//) : PlatformView {
//
//    private val dotLottieView: DotLottieAnimation = DotLottieAnimation(context)
//
//    init {
//        // Load animation from creation params
//        creationParams?.let { params ->
//            val sourceType = params["sourceType"] as? String
//            val source = params["source"] as? String
//            val autoplay = params["autoplay"] as? Boolean ?: true
//            val loop = params["loop"] as? Boolean ?: true
//            val speed = (params["speed"] as? Number)?.toFloat() ?: 1f
//
//            if (sourceType != null && source != null) {
//                val dotLottieSource = when (sourceType) {
//                    "url" -> DotLottieSource.Url(source)
//                    "asset" -> DotLottieSource.Asset(source)
//                    "json" -> DotLottieSource.Json(source)
//                    else -> return@let
//                }
//
//                val config = Config.Builder()
//                    .autoplay(autoplay)
//                    .loop(loop)
//                    .speed(speed)
//                    .source(dotLottieSource)
//                    .playMode(Mode.FORWARD)
//                    .build()
//
//                dotLottieView.load(config)
//            }
//        }
//    }
//
//    override fun getView(): DotLottieAnimation {
//        return dotLottieView
//    }
//
//    override fun dispose() {
//        dotLottieView.stop()
//    }
//}



class DotlottieFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    // Store references to platform views
    companion object {
        lateinit var binaryMessenger: io.flutter.plugin.common.BinaryMessenger
        val platformViews = mutableMapOf<Int, DotLottiePlatformView>()
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("🔴 DotLottie", "Plugin attached to engine")

        // Store the binary messenger
        binaryMessenger = flutterPluginBinding.binaryMessenger

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dotlottie_flutter")
        channel.setMethodCallHandler(this)

        // Register platform view factory
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "dotlottie_view",
                DotLottieViewFactory()
            )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("🔴 DotLottie", "Attached to activity")
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d("🔴 DotLottie", "Method called: ${call.method}")

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activity = null
    }
}

class DotLottieViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val view = DotLottiePlatformView(context, viewId, args as? Map<String, Any>)
        DotlottieFlutterPlugin.platformViews[viewId] = view
        return view
    }
}


class DotLottiePlatformView(
    context: Context,
    private val viewId: Int,
    creationParams: Map<String, Any>?
) : PlatformView {

    private val dotLottieView: DotLottieAnimation = DotLottieAnimation(context)
    private val methodChannel: MethodChannel

    init {
        Log.d("🔴 DotLottie", "Creating platform view with id: $viewId")
        
        val layoutParams = android.view.ViewGroup.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.ViewGroup.LayoutParams.MATCH_PARENT
        )
        dotLottieView.layoutParams = layoutParams
        
        methodChannel = MethodChannel(
            DotlottieFlutterPlugin.binaryMessenger,
            "dotlottie_view_$viewId"
        )
    
        // Load animation from creation params
        creationParams?.let { params ->
            val sourceType = params["sourceType"] as? String
            val source = params["source"] as? String
            val autoplay = params["autoplay"] as? Boolean ?: true
            val loop = params["loop"] as? Boolean ?: true
            val speed = (params["speed"] as? Number)?.toFloat() ?: 1f

            dotLottieView.post {
                Log.d("🔴 DotLottie", "Inside post() - setting up listener and loading")

                // Add event listener RIGHT BEFORE loading
                Log.d("🔴 DotLottie", "Adding event listener")
                dotLottieView.addEventListener(object : DotLottieEventListener {
                    override fun onLoad() {
                        Log.d("🔴 DotLottie", "✅✅✅ onLoad triggered on view $viewId")
                        methodChannel.invokeMethod("onLoad", null)
                    }

                    override fun onPlay() {
                        Log.d("🔴 DotLottie", "✅✅✅ onPlay triggered")
                        methodChannel.invokeMethod("onPlay", null)
                    }

                    override fun onPause() {
                        Log.d("🔴 DotLottie", "✅ onPause triggered")
                        methodChannel.invokeMethod("onPause", null)
                    }

                    override fun onStop() {
                        Log.d("🔴 DotLottie", "✅ onStop triggered")
                        methodChannel.invokeMethod("onStop", null)
                    }

                    override fun onComplete() {
                        Log.d("🔴 DotLottie", "✅ onComplete triggered")
                        methodChannel.invokeMethod("onComplete", null)
                    }

                    override fun onFrame(frame: Float) {
                        methodChannel.invokeMethod("onFrame", mapOf("frame" to frame.toDouble()))
                    }

                    override fun onLoop(loopCount: Int) {
                        Log.d("🔴 DotLottie", "✅ onLoop triggered")
                        methodChannel.invokeMethod("onLoop", null)
                    }

                    override fun onFreeze() {
                        Log.d("🔴 DotLottie", "⚠️ onFreeze called")
                    }

                    override fun onUnFreeze() {
                        Log.d("🔴 DotLottie", "⚠️ onUnFreeze called")
                    }

                    override fun onDestroy() {
                        Log.d("🔴 DotLottie", "⚠️ onDestroy called")
                    }
                })
                Log.d("🔴 DotLottie", "Event listener added")

                if (sourceType != null && source != null) {
                    Log.d("🔴 DotLottie", "Source: $source, Type: $sourceType")

                    val dotLottieSource = when (sourceType) {
                        "url" -> {
                            Log.d("🔴 DotLottie", "Creating URL source for: $source")
                            DotLottieSource.Url(source)
                        }
                        "asset" -> DotLottieSource.Asset(source)
                        "json" -> DotLottieSource.Json(source)
                        else -> {
                            Log.e("🔴 DotLottie", "Invalid source type: $sourceType")
                            return@post
                        }
                    }

                    try {
                        val config = Config.Builder()
                            .autoplay(autoplay)
                            .loop(loop)
                            .speed(speed)
                            .source(dotLottieSource)
                            .playMode(Mode.FORWARD)
                            .build()

                        Log.d("🔴 DotLottie", "Calling load() with URL")
                        dotLottieView.load(config)
                        Log.d("🔴 DotLottie", "load() returned, waiting for onLoad callback...")

                        // Add a timeout check
                        dotLottieView.postDelayed({
                            Log.w("🔴 DotLottie", "5 seconds passed, still no onLoad. Animation may have failed to load from URL.")
                        }, 5000)
                    } catch (e: Exception) {
                        Log.e("🔴 DotLottie", "Exception during load: ${e.message}", e)
                    }
                }
            }
        }
    }

    override fun getView(): DotLottieAnimation {
        return dotLottieView
    }

    override fun dispose() {
        Log.d("🔴 DotLottie", "Disposing view $viewId")
        dotLottieView.stop()
        DotlottieFlutterPlugin.platformViews.remove(viewId)
    }
}
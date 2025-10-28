package com.lottiefiles.dotlottie_flutter

import android.content.Context
import android.util.Log
import com.dotlottie.dlplayer.Mode
import com.lottiefiles.dotlottie.core.model.Config
import com.lottiefiles.dotlottie.core.util.DotLottieEventListener
import com.lottiefiles.dotlottie.core.util.DotLottieSource
import com.lottiefiles.dotlottie.core.widget.DotLottieAnimation
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class DotLottiePlatformView(
        context: Context,
        private val viewId: Int,
        creationParams: Map<String, Any>?
) : PlatformView {
    private val dotLottieView: DotLottieAnimation = DotLottieAnimation(context)
    private val methodChannel: MethodChannel

    init {
        Log.d("🔴 DotLottie", "Creating platform view with id: $viewId")

        val layoutParams =
            android.view.ViewGroup.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.view.ViewGroup.LayoutParams.MATCH_PARENT
            )
        dotLottieView.layoutParams = layoutParams

        methodChannel =
            MethodChannel(DotLottieFlutterPlugin.binaryMessenger, "dotlottie_view_$viewId")

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
                dotLottieView.addEventListener(
                    object : DotLottieEventListener {
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
                            methodChannel.invokeMethod(
                                "onFrame",
                                mapOf("frame" to frame.toDouble())
                            )
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
                    }
                )
                Log.d("🔴 DotLottie", "Event listener added")

                if (sourceType != null && source != null) {
                    Log.d("🔴 DotLottie", "Source: $source, Type: $sourceType")

                    val dotLottieSource =
                        when (sourceType) {
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
                        val config =
                            Config.Builder()
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
                        dotLottieView.postDelayed(
                            {
                                Log.w(
                                    "🔴 DotLottie",
                                    "5 seconds passed, still no onLoad. Animation may have failed to load from URL."
                                )
                            },
                            5000
                        )
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
        DotLottieFlutterPlugin.platformViews.remove(viewId)
    }
}
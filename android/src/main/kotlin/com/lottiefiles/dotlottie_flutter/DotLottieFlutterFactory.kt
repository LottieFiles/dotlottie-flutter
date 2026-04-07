package com.lottiefiles.dotlottie_flutter

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class DotLottieViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        val useOpenGL = creationParams?.get("useOpenGL") as? Boolean ?: false

        // Create method channel for this specific view
        val methodChannel = MethodChannel(
            DotLottieFlutterPlugin.binaryMessenger,
            "dotlottie_view_$viewId"
        )

        val view = DotLottiePlatformView(context, viewId, creationParams, useOpenGL)

        // Store reference
        DotLottieFlutterPlugin.platformViews[viewId] = view

        return view
    }
}
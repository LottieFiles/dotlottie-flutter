package com.lottiefiles.dotlottie_flutter

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** One per engine: [messenger] and [platformViews] belong to the engine that registered it. */
class DotLottieViewFactory(
    private val messenger: BinaryMessenger,
    private val platformViews: MutableMap<Int, DotLottiePlatformView>,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any>
        val useOpenGL = creationParams?.get("useOpenGL") as? Boolean ?: false

        val view = DotLottiePlatformView(
            context, viewId, creationParams, useOpenGL, messenger,
            onDisposed = { id -> platformViews.remove(id) },
        )
        platformViews[viewId] = view
        return view
    }
}

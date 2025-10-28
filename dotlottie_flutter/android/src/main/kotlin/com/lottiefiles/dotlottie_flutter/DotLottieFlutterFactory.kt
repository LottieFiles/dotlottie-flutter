package com.lottiefiles.dotlottie_flutter

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class DotLottieViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val view = DotLottiePlatformView(context, viewId, args as? Map<String, Any>)
        DotLottieFlutterPlugin.platformViews[viewId] = view
        return view
    }
}

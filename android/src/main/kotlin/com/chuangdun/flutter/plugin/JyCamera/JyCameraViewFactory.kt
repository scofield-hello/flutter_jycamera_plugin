package com.chuangdun.flutter.plugin.JyFaceCompare

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class JyCameraViewFactory(context: Context, private val messenger: BinaryMessenger)
    :PlatformViewFactory(StandardMessageCodec.INSTANCE){

    override fun create(context: Context, viewId: Int, createParams: Any): PlatformView {
        return JyCameraView(context, messenger = messenger, id = viewId, createParams = createParams as Map<*, *>)
    }
}
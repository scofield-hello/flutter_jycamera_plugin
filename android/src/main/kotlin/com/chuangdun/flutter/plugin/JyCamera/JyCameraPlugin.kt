package com.chuangdun.flutter.plugin.JyCamera

import androidx.annotation.NonNull
import com.chuangdun.flutter.plugin.JyFaceCompare.JyCameraViewFactory

import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "JyCameraPlugin"
const val VIEW_REGISTRY_NAME = "JyCameraView"
const val VIEW_EVENT_REGISTRY_NAME = "JyCameraViewEvent"
/** JyCameraPlugin */
class JyCameraPlugin: FlutterPlugin {

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val viewFactory = JyCameraViewFactory(flutterPluginBinding.applicationContext,
            flutterPluginBinding.binaryMessenger)
    flutterPluginBinding.platformViewRegistry.registerViewFactory(VIEW_REGISTRY_NAME, viewFactory)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}

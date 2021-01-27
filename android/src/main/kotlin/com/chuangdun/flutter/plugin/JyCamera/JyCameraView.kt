package com.chuangdun.flutter.plugin.JyFaceCompare

import android.content.Context
import android.graphics.Bitmap

import android.os.Handler
import android.util.Log
import android.view.Gravity
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import com.camera.CameraConstant
import com.camera.JYCamera
import com.camera.entity.CameraResolution
import com.camera.impl.CameraCallback
import com.chuangdun.flutter.plugin.JyCamera.VIEW_EVENT_REGISTRY_NAME
import com.chuangdun.flutter.plugin.JyCamera.VIEW_REGISTRY_NAME
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream

private const val EVENT_CAMERA_OPENED = 0
private const val EVENT_PREVIEW = 1
private const val EVENT_PREVIEW_STOP = 2
private const val EVENT_CAMERA_CLOSED = 3
private const val EVENT_PHOTO_TOKEN = 4

private const val TAG = "JyCameraView"

class JyCameraView(private val context: Context, messenger: BinaryMessenger, id: Int, createParams: Map<*,*>) : PlatformView,
        MethodChannel.MethodCallHandler, EventChannel.StreamHandler{

    private val textureView: TextureView = TextureView(context)
    private val methodChannel = MethodChannel(messenger, "${VIEW_REGISTRY_NAME}_$id")
    private var eventChannel = EventChannel(messenger, "${VIEW_EVENT_REGISTRY_NAME}_$id")
    private val uiHandler = Handler()
    private var eventSink: EventChannel.EventSink? = null
    private val mCamera: JYCamera
    private var mRotate = 0
    private var mCameraId = 2

    init {
        val width = createParams["width"] as Int
        val height = createParams["height"] as Int
        mRotate = createParams["rotate"] as Int
        val previewWidth = createParams["previewWidth"] as Int
        val previewHeight = createParams["previewHeight"] as Int
        val pictureWidth = createParams["pictureWidth"] as Int
        val pictureHeight = createParams["pictureHeight"] as Int
        textureView.layoutParams = ViewGroup.LayoutParams(width, height)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        mCamera = initCamera(previewWidth, previewHeight, pictureWidth, pictureHeight, mRotate)
    }


    private fun initCamera(previewWidth:Int, previewHeight:Int, pictureWidth:Int, pictureHeight: Int, rotate:Int):JYCamera{
        return JYCamera.Builder(context)
                .setCameraType(CameraConstant.CAMERA_1)
                .setCameraPreviewSize(previewWidth, previewHeight)
                .setCameraPictureSize(pictureWidth, pictureHeight)
                .setCameraRotation(rotate)
                .setTakeCallback { bytes, _, code ->
                    Log.d(TAG, "onPictureTaken.")
                    uiHandler.post {
                        eventSink?.success(mapOf(
                                "event" to EVENT_PHOTO_TOKEN,
                                "imageData" to bytes,
                                "code" to code
                        ))
                    }
                }
                .setCameraCallback(object : CameraCallback {
                    override fun onOpenedCamera() {
                        Log.d(TAG, "Camera opened.")
                        uiHandler.post {
                            eventSink?.success(mapOf(
                                    "event" to EVENT_CAMERA_OPENED
                            ))
                        }
                    }

                    override fun onPreviewFrame(yuvData: ByteArray, bitmap: Bitmap, width: Int, height: Int) {
                        //Log.d(TAG, "Preview onFrame: width:$width, height:$height")
                        uiHandler.post {
                            eventSink?.success(mapOf(
                                    "event" to EVENT_PREVIEW,
                                    "yuvData" to yuvData,
                                    "width" to width,
                                    "height" to height
                            ))
                        }
                    }

                    override fun onClosedCamera() {
                        Log.d(TAG, "Camera closed")
                        uiHandler.post {
                            eventSink?.success(mapOf(
                                    "event" to EVENT_CAMERA_CLOSED
                            ))
                        }
                    }

                    override fun onStopPreview() {
                        Log.d(TAG, "Preview stop")
                        uiHandler.post {
                            eventSink?.success(mapOf(
                                    "event" to EVENT_PREVIEW_STOP
                            ))
                        }
                    }
                })
                .build()
    }


    override fun getView(): View {
        Log.i(TAG, "JyCameraView:getView")
        return textureView
    }

    override fun onFlutterViewAttached(flutterView: View) {
        Log.i(TAG, "JyCameraView:onFlutterViewAttached")
    }

    override fun onFlutterViewDetached() {
        Log.i(TAG, "JyCameraView:onFlutterViewDetached")
    }

    override fun dispose() {
        Log.i(TAG, "JyCameraView:dispose")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.i(TAG, "JyCameraView:onMethodCall:${call.method}")
        when(call.method){
            "startPreview" -> {
                mCamera.doStartPreview(mCameraId, textureView)
            }
            "stopPreview" -> {
                mCamera.doStopPreview()
            }
            "rotate" -> {
                mRotate += 90
                mRotate = if(mRotate == 360) 0 else mRotate
                mCamera.rotateDegree(mRotate.toFloat())
            }
            "mirror" -> {
                mCamera.mirror()
            }
            "takePicture" -> {
                val arguments = call.arguments as Map<*,*>
                val savePath = arguments["savePath"] as String?
                val bitmap = if (savePath == null){
                    mCamera.takePicture()
                }else{
                    mCamera.takePicture(savePath)
                }
                val outputStream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                val bitmapData = outputStream.toByteArray()
                result.success(bitmapData)
            }
            "takePhoto" -> {
                val arguments = call.arguments as Map<*,*>
                val code = arguments["code"] as Int?
                if (code == null || code == 0){
                    mCamera.takePhoto()
                }else{
                    mCamera.takePhoto(code)
                }
            }
            "getCameraIdList" -> {
                result.success(mCamera.cameraIDList)
            }
            "getCameraResolutionList" -> {
                val resolutions = mCamera.cameraResolutionList
                val supportedResolutions = mutableListOf<Map<String, Int>>()
                if (resolutions != null){
                    for (resolution in resolutions){
                        supportedResolutions.add(mapOf(
                                "width" to resolution.width,
                                "height" to resolution.height
                        ))
                    }
                }
                result.success(supportedResolutions)
            }
            "switchCamera" -> {
                val arguments = call.arguments as Map<*,*>
                mCameraId = arguments["cameraId"] as Int
                mCamera.switchCamera(mCameraId)
            }
            "switchResolutionIndex" -> {
                val arguments = call.arguments as Map<*,*>
                val previewIndex = arguments["previewResolutionIndex"] as Int
                val pictureIndex = arguments["pictureResolutionIndex"] as Int
                mCamera.switchResolutionIndex(previewIndex, pictureIndex)
            }
            "switchResolution" -> {
                val arguments = call.arguments as List<*>
                val previewMap = arguments[0] as Map<*,*>
                val pictureMap = arguments[1] as Map<*,*>
                val previewResolution = CameraResolution(previewMap["width"] as Int, previewMap["height"] as Int)
                val pictureResolution = CameraResolution(pictureMap["width"] as Int, pictureMap["height"] as Int)
                mCamera.switchResolution(previewResolution, pictureResolution)
            }
            "switchResolutionSize" ->{
                val arguments = call.arguments as Map<*,*>
                val width = arguments["width"] as Int
                val height = arguments["height"] as Int
                mCamera.switchResolution(width, height)
            }
            "stopCamera" -> {
                mCamera.doStopCamera()
            }
            "releaseCamera" -> {
                mCamera.releaseAll()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class JyCameraViewParams{
  final int width;
  final int height;
  final int rotate;
  final int previewWidth;
  final int previewHeight;
  final int pictureWidth;
  final int pictureHeight;
  const JyCameraViewParams({
    this.width=-1, this.height=-1, this.rotate=0,
    this.previewWidth=1280, this.previewHeight=960, this.pictureHeight=1280,
    this.pictureWidth=960});

  Map<String, dynamic> asJson(){
    return {
      "width": width,
      "height": height,
      "rotate": rotate,
      "previewWidth":previewWidth,
      "previewHeight":previewHeight,
      "pictureWidth":pictureWidth,
      "pictureHeight":pictureHeight
    };
  }
}

class JyCameraView extends StatelessWidget {
  final _viewType = "JyCameraView";
  final JyCameraViewParams creationParams;
  final JyCameraViewController controller;
  final VoidCallback onJyCameraViewCreated;
  const JyCameraView(
      {Key key, this.controller, this.onJyCameraViewCreated,
        this.creationParams = const JyCameraViewParams()})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AndroidView(
        viewType: _viewType,
        creationParams: creationParams.asJson(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated);
  }

  void _onPlatformViewCreated(int id) {
    if (controller != null) {
      controller.onCreate(id);
    }
    if (onJyCameraViewCreated != null) {
      onJyCameraViewCreated();
    }
  }
}

class JyCameraEventType {
  static const EVENT_CAMERA_OPENED = 0;
  static const EVENT_PREVIEW = 1;
  static const EVENT_PREVIEW_STOP = 2;
  static const EVENT_CAMERA_CLOSED = 3;
  static const EVENT_PHOTO_TOKEN = 4;
}

class PhotoResult{
  final int code;
  final Uint8List imageData;
  const PhotoResult(this.imageData, this.code);
}

class PreviewFrameResult{
  final int height;
  final int width;
  final Uint8List yuvData;
  const PreviewFrameResult(this.yuvData, this.width, this.height);
}

class CameraResolution{
  final int height;
  final int width;
  const CameraResolution(this.width, this.height);

  Map<String, int> asJson(){
    return {
      "width": width,
      "height": height
    };
  }
}

class JyCameraViewController {
  static const _EVENT_CHANNEL_NAME = "JyCameraViewEvent";
  static const _METHOD_CHANNEL_NAME = "JyCameraView";
  MethodChannel _methodChannel;
  EventChannel _eventChannel;

  void _onEvent(dynamic event) {
    switch (event['event']) {
      case JyCameraEventType.EVENT_CAMERA_OPENED:
        if(!_onCameraOpened.isClosed){
          _onCameraOpened.add(null);
        }
        break;
      case JyCameraEventType.EVENT_PREVIEW:
        if(!_onPreview.isClosed){
          _onPreview.add(PreviewFrameResult(event['yuvData'], event['width'], event['height']));
        }
        break;
      case JyCameraEventType.EVENT_PREVIEW_STOP:
        if(!_onPreviewStop.isClosed){
          _onPreviewStop.add(null);
        }
        break;
      case JyCameraEventType.EVENT_CAMERA_CLOSED:
        if(!_onCameraClosed.isClosed){
          _onCameraClosed.add(null);
        }
        break;
      case JyCameraEventType.EVENT_PHOTO_TOKEN:
        if(!_onPhotoToken.isClosed){
          _onPhotoToken.add(PhotoResult(event['imageData'], event['code']));
        }
        break;
      default:
        break;
    }
  }

  onCreate(int id) {
    _methodChannel = MethodChannel("${_METHOD_CHANNEL_NAME}_$id");
    _eventChannel = EventChannel("${_EVENT_CHANNEL_NAME}_$id");
    _eventChannel.receiveBroadcastStream().listen(_onEvent);
  }

  final _onCameraOpened = StreamController<void>.broadcast();
  ///相机打开时触发.
  Stream<void> get onCameraOpened => _onCameraOpened.stream;

  final _onPreview = StreamController<PreviewFrameResult>.broadcast();
  ///每一帧预览画面都会触发.
  Stream<PreviewFrameResult> get onPreview => _onPreview.stream;

  final _onPreviewStop = StreamController<void>.broadcast();
  ///预览停止时触发.
  Stream<void> get onPreviewStop => _onPreviewStop.stream;

  final _onCameraClosed = StreamController<void>.broadcast();
  ///相机关闭时触发.
  Stream<void> get onCameraClosed => _onCameraClosed.stream;

  final _onPhotoToken = StreamController<PhotoResult>.broadcast();
  ///调用[takePhoto]拍摄照片后触发.
  Stream<PhotoResult> get onPhotoToken => _onPhotoToken.stream;

  ///开始预览画面,需要调用两次.
  Future<void> startPreview() async {
    _methodChannel.invokeMethod("startPreview");
  }

  ///调整图像旋转角度,每次角度+90，在[0...360]之间.
  Future<void> rotate() async {
    _methodChannel.invokeMethod("rotate");
  }

  ///设置初始化画面镜像.
  Future<void> mirror() async {
    _methodChannel.invokeMethod("mirror");
  }

  ///拍摄照片.
  Future<Uint8List> takePicture([String savePath]) async {
    return await _methodChannel.invokeMethod("takePicture",{"savePath":savePath});
  }

  ///高分辨率拍摄照片.
  ///在[onPhotoToken]中返回拍摄的图像数据.
  Future<void> takePhoto([int code]) async {
    _methodChannel.invokeMethod("takePhoto",{"code":code});
  }

  ///获取相机ID列表.
  Future<List<String>> getCameraIdList() async {
    return await _methodChannel.invokeMethod("getCameraIdList");
  }

  ///获取相机支持的分辨率列表.
  Future<List<CameraResolution>> getCameraResolutionList() async {
    List<dynamic> resolutions = await _methodChannel.invokeMethod("getCameraResolutionList");
    return resolutions.map((e) => CameraResolution(e['width'], e['height'])).toList();
  }

  ///切换摄像头.
  Future<void> switchCamera(int cameraId) async {
    assert(cameraId != null && cameraId >=0 && cameraId <= 2);
    _methodChannel.invokeMethod("switchCamera",{"cameraId":cameraId});
  }

  ///切换分辨率.
  ///[previewResolutionIndex] 预览分辨率下标.
  ///[pictureResolutionIndex] 照片分辨率下标,默认与预览分辨率下标相同.
  Future<void> switchResolutionIndex(int previewResolutionIndex,
      [int pictureResolutionIndex]) async {
    assert(previewResolutionIndex != null && previewResolutionIndex >=0);
    if(pictureResolutionIndex == null){
      pictureResolutionIndex = previewResolutionIndex;
    }
    assert(pictureResolutionIndex != null && pictureResolutionIndex >=0);
    _methodChannel.invokeMethod("switchResolutionIndex",
        {
          "previewResolutionIndex": previewResolutionIndex,
          "pictureResolutionIndex": pictureResolutionIndex
        });
  }

  ///切换分辨率.
  ///[previewResolution] 预览分辨率.
  ///[pictureResolutionIndex] 照片分辨率下标,默认与预览分辨率相同.
  Future<void> switchResolution(CameraResolution previewResolution,
      [CameraResolution pictureResolution]) async {
    assert(previewResolution != null && previewResolution.width >0 && previewResolution.height > 0);
    if(pictureResolution == null){
      pictureResolution = previewResolution;
    }
    assert(pictureResolution != null && pictureResolution.width >0 && pictureResolution.height > 0);
    _methodChannel.invokeMethod("switchResolution",
        [
          previewResolution.asJson(),
          pictureResolution.asJson()
        ]);
  }

  ///切换分辨率.
  ///[width] 宽,[height] 高
  Future<void> switchResolutionSize(int width, int height) async {
    assert(width != null && height != null && width >0 && height > 0);
    _methodChannel.invokeMethod("switchResolutionSize",
        {"width": width, "height": height});
  }

  ///关闭预览.
  Future<void> stopPreview() async {
    _methodChannel.invokeMethod("stopPreview");
  }

  ///关闭相机.
  ///关闭相机前请调用[stopPreview]停止预览.
  Future<void> stopCamera() async {
    _methodChannel.invokeMethod("stopCamera");
  }

  ///释放所有相机资源.
  ///释放之前请调用[stopPreview],[stopCamera]关闭相机
  Future<void> releaseCamera() async {
    _methodChannel.invokeMethod("releaseCamera");
  }

  void dispose() {
    _onCameraOpened.close();
    _onPhotoToken.close();
    _onPreview.close();
    _onPreviewStop.close();
    _onCameraClosed.close();
  }
}
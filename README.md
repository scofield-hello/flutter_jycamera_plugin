# JyCamera

捷宇一体机相机Flutter插件.

## Getting Started

```dart
JyCameraViewController _controller;
List<CameraResolution> _resolutions = [];

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _controller = JyCameraViewController();
  _controller.onCameraOpened.listen((_) async {
    print("onCameraOpened");
    var list = await _controller.getCameraResolutionList();
    setState(() {
      _resolutions = list;
    });
  });
  _controller.onCameraClosed.listen((_) {
    print("onCameraClosed");
  });
  _controller.onPreviewStop.listen((_) {
    print("onPreviewStop");
  });
  _controller.onPhotoToken.listen((photoResult) {
    print("高清照片:${photoResult.code}, 照片长度:${photoResult.imageData.length}");
  });
}

void _onJyCameraViewCreated() {
  print("_onJyCameraViewCreated");
  Future.delayed(Duration(milliseconds: 500), () {
    _controller.startPreview();
  }).then((_) {
    _controller.startPreview();
  });
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      print("didChangeAppLifecycleState:resume");
      _controller.startPreview();
      break;
    case AppLifecycleState.inactive:
      print("didChangeAppLifecycleState:inactive");
      break;
    case AppLifecycleState.paused:
      print("didChangeAppLifecycleState:pause");
      _controller.stopPreview();
      break;
    default:
      break;
  }
}

@override
void dispose() {
  super.dispose();
  WidgetsBinding.instance.removeObserver(this);
  _controller.stopCamera();
  _controller.releaseCamera();
  _controller.dispose();
}

//旋转预览
_controller.rotate();

//获取支持的分辨率列表
List<CameraResolution> _resolutions = await _controller.getCameraResolutionList();

//切换分辨率
_controller.switchResolution(_resolutions[index]);
_controller.switchResolutionSize(int width, int height);
_controller.switchResolutionIndex(int index);

//拍摄照片
var bitmapData = await _controller.takePicture();
print("图像长度:${bitmapData.length}");

//拍摄高清照片,结果在[onPhotoToken]中返回
await _controller.takePhoto();

```


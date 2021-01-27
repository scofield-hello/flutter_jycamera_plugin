import 'package:JyCamera/JyCamera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
      print("拍摄高清照片:${photoResult.code}, 照片长度:${photoResult.imageData.length}");
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
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
            child: Row(mainAxisSize: MainAxisSize.max, children: [
          Container(
            width: 1134,
            height: 800,
            color: Colors.black,
            alignment: Alignment.center,
            child: Container(
              width: 800,
              height: 600,
              alignment: Alignment.center,
              child: JyCameraView(
                controller: _controller,
                onJyCameraViewCreated: _onJyCameraViewCreated,
                creationParams: const JyCameraViewParams(
                    width: 800,
                    height: 600,
                    rotate: 0,
                    previewWidth: 2592,
                    previewHeight: 1944,
                    pictureWidth: 2592,
                    pictureHeight: 1944),
              ),
            ),
          ),
          Container(
            width: 146,
            height: 800,
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100.0),
                FlatButton(
                    onPressed: () {
                      _controller.rotate();
                    },
                    child: Text(
                      "旋转",
                      style: TextStyle(color: Colors.white),
                    )),
                SizedBox(height: 20.0),
                FlatButton(
                    onPressed: () async {
                      var bitmapData = await _controller.takePicture();
                      print("图像长度:${bitmapData.length}");
                    },
                    child: Text(
                      "拍照",
                      style: TextStyle(color: Colors.white),
                    )),
                SizedBox(height: 10.0),
                FlatButton(
                    onPressed: () async {
                      await _controller.takePhoto();
                    },
                    child: Text(
                      "拍摄高清照片",
                      style: TextStyle(color: Colors.white),
                    )),
                Expanded(
                    child: ListView.builder(
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _controller.switchResolution(_resolutions[index]);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 16.0),
                        child: Text(
                          "${_resolutions[index].width} * ${_resolutions[index].height}",
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ),
                    );
                  },
                  itemCount: _resolutions.length,
                ))
              ],
            ),
          )
        ])));
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
}

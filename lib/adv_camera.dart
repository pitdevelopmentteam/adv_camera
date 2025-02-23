library adv_camera;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'controller.dart';

//class AdvCamera {
//  static const MethodChannel _channel =
//      const MethodChannel('adv_camera');
//
//  static Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }
//}

enum FlashType { auto, on, off, torch }
enum CameraType { front, rear }
enum CameraPreviewRatio { r16_9, r11_9, r4_3, r1 }
enum CameraSessionPreset { low, medium, high, photo }

typedef void CameraCreatedCallback(AdvCameraController controller);
typedef void ImageCapturedCallback(String path);

class AdvCamera extends StatefulWidget {
  final CameraType initialCameraType;
  final CameraPreviewRatio cameraPreviewRatio;
  final CameraSessionPreset cameraSessionPreset;
  final CameraCreatedCallback onCameraCreated;
  final ImageCapturedCallback onImageCaptured;
  final FlashType flashType;
  final bool bestPictureSize;

  const AdvCamera(
      {Key key,
      CameraType initialCameraType,
      CameraPreviewRatio cameraPreviewRatio,
      CameraSessionPreset cameraSessionPreset,
        FlashType flashType,
        bool bestPictureSize,
      this.onCameraCreated,
      this.onImageCaptured})
      : this.initialCameraType = initialCameraType ?? CameraType.rear,
        this.cameraPreviewRatio = cameraPreviewRatio ?? CameraPreviewRatio.r16_9,
        this.cameraSessionPreset = cameraSessionPreset ?? CameraSessionPreset.photo,
        this.flashType = flashType ?? FlashType.auto,
        this.bestPictureSize = bestPictureSize ?? true,
        super(key: key);

  @override
  _AdvCameraState createState() => _AdvCameraState();
}

class _AdvCameraState extends State<AdvCamera> {
  Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  CameraPreviewRatio _cameraPreviewRatio;
  CameraSessionPreset _cameraSessionPreset;
  FlashType _flashType;

  @override
  void initState() {
    super.initState();
    _cameraPreviewRatio = widget.cameraPreviewRatio;
    _cameraSessionPreset = widget.cameraSessionPreset;
    _flashType = widget.flashType;
  }

  @override
  Widget build(BuildContext context) {
    String previewRatio;
    String sessionPreset;
    String flashType;

    switch (_flashType) {
      case FlashType.on:
        flashType = "on";
        break;
      case FlashType.off:
        flashType = "off";
        break;
      case FlashType.auto:
        flashType = "auto";
        break;
      case FlashType.torch:
        flashType = "torch";
        break;
    }

    switch (_cameraPreviewRatio) {
      case CameraPreviewRatio.r16_9:
        previewRatio = "16:9";
        break;
      case CameraPreviewRatio.r11_9:
        previewRatio = "11:9";
        break;
      case CameraPreviewRatio.r4_3:
        previewRatio = "4:3";
        break;
      case CameraPreviewRatio.r1:
        previewRatio = "1:1";
        break;
    }

    switch (_cameraSessionPreset) {
      case CameraSessionPreset.low:
        sessionPreset = "low";
        break;
      case CameraSessionPreset.medium:
        sessionPreset = "medium";
        break;
      case CameraSessionPreset.high:
        sessionPreset = "high";
        break;
      case CameraSessionPreset.photo:
        sessionPreset = "photo";
        break;
    }

    final Map<String, dynamic> creationParams = <String, dynamic>{
      "initialCameraType": widget.initialCameraType == CameraType.rear ? "rear" : "front",
      "previewRatio": previewRatio,
      "sessionPreset": sessionPreset,
      "flashType": flashType,
      "fileNamePrefix": "adv_camera",
      "bestPictureSize": widget.bestPictureSize, //for first run on Android (because on each device the default picture size is vary, for example MI 8 Lite's default is the lowest resolution)
    };

    Widget camera;

    if (defaultTargetPlatform == TargetPlatform.android) {
      camera = AndroidView(
        viewType: 'plugins.flutter.io/adv_camera',
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      camera = UiKitView(
        viewType: 'plugins.flutter.io/adv_camera',
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double lesser;
        double greater;
        double widthTemp;
        double heightTemp;
        double width;
        double height;
        double selectedPreviewRatio;
        double constraintRatio;

        if (constraints.maxWidth < constraints.maxHeight) {
          greater = constraints.maxHeight;
          lesser = constraints.maxWidth;
          constraintRatio = constraints.maxWidth / constraints.maxHeight;
        } else {
          greater = constraints.maxWidth;
          lesser = constraints.maxHeight;
          constraintRatio = constraints.maxHeight / constraints.maxWidth;
        }

        switch (_cameraPreviewRatio) {
          case CameraPreviewRatio.r16_9:
            selectedPreviewRatio = 9.0 / 16.0;
            if (constraintRatio >= selectedPreviewRatio) {
              widthTemp = lesser;
              heightTemp = lesser * 16.0 / 9.0;
            } else {
              heightTemp = greater;
              widthTemp = greater * 9.0 / 16.0;
            }
            break;
          case CameraPreviewRatio.r11_9:
            selectedPreviewRatio = 9.0 / 11.0;
            if (constraintRatio >= selectedPreviewRatio) {
              widthTemp = lesser;
              heightTemp = lesser * 11.0 / 9.0;
            } else {
              heightTemp = greater;
              widthTemp = greater * 9.0 / 11.0;
            }
            break;
          case CameraPreviewRatio.r4_3:
            selectedPreviewRatio = 3.0 / 4.0;
            if (constraintRatio >= selectedPreviewRatio) {
              widthTemp = lesser;
              heightTemp = lesser * 4.0 / 3.0;
            } else {
              heightTemp = greater;
              widthTemp = greater * 3.0 / 4.0;
            }
            break;
          case CameraPreviewRatio.r1:
            if (constraintRatio >= 1.0) {
              widthTemp = lesser;
              heightTemp = lesser;
            } else {
              heightTemp = greater;
              widthTemp = greater;
            }
            break;
        }

        if (Platform.isAndroid) {
          if (constraints.maxWidth < constraints.maxHeight) {
            width = widthTemp;
            height = heightTemp;
          } else {
            width = heightTemp;
            height = widthTemp;
          }
        } else {
          width = constraints.maxWidth;
          height = constraints.maxHeight;
        }

        return ClipRect(
          child: OverflowBox(
            maxWidth: width,
            maxHeight: height,
            child: camera,
          ),
          clipper: CustomRect(
            right: constraints.maxWidth,
            bottom: constraints.maxHeight,
          ),
        );
      },
    );
  }

  Future<void> onPlatformViewCreated(int id) async {
    final AdvCameraController controller = await AdvCameraController.init(
      id,
      this,
    );

    if (widget.onCameraCreated != null) {
      widget.onCameraCreated(controller);
    }
  }

  /// @return the greatest common denominator
  int findGcm(int a, int b) {
    return b == 0 ? a : findGcm(b, a % b); // Not bad for one line of code :)
  }

  String asFraction(int a, int b) {
    int gcm = findGcm(a, b);
    return "${(a / gcm)} : ${(b / gcm)}";
  }

  void onImageCaptured(String path) {
    if (widget.onImageCaptured != null) {
      widget.onImageCaptured(path);
    }
  }
}

class CustomRect extends CustomClipper<Rect> {
  final double right;
  final double bottom;

  CustomRect({this.right, this.bottom});

  @override
  Rect getClip(Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, right, bottom);
    return rect;
  }

  @override
  bool shouldReclip(CustomRect oldClipper) {
    return true;
  }
}

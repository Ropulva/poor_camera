import 'dart:async';

import 'dart:js_interop';
// Camera info returned by getAvailableCameras
@JS()
@staticInterop
class CameraInfo {}
extension CameraInfoExtension on CameraInfo {
  external JSString get deviceId;
  external JSString get label;
  external JSString get facingMode;
}

@JS('getAvailableCameras')
external JSPromise<JSArray> getAvailableCameras();

@JS('startCamera')
external JSPromise<JSArray> _startCamera(String videoElementId, [String? deviceId, String facingMode]);

@JS('stopCamera')
external void stopCamera();

@JS('takePicture')
external JSPromise<JSString?> _takePicture();

class CameraService {

  static Future<List<CameraInfo>> fetchAvailableCameras() async {
    final jsArray = await getAvailableCameras().toDart;
    final cameras = jsArray.toDart.cast<CameraInfo>();
    return cameras;
  }

  static Future<(bool, String?)> startCameraDevice(
      String videoElementId, {String? deviceId, String facingMode = 'environment'}
      ) async
  {
    final result = await _startCamera(videoElementId, deviceId, facingMode).toDart;
    final tuple = result.toDart;
    return (tuple[0] as bool, tuple[1] as String?);
  }

  static void stop() => stopCamera();

  static Future<String?> takePicture() async {
    final jsString = await _takePicture().toDart;
    return jsString?.toDart;
  }
}
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
    try {
      final jsArray = await getAvailableCameras().toDart;
      return jsArray.toDart.cast<CameraInfo>();
    } catch (_) {
      return [];
    }
  }

  /// Returns whether the camera started, the error if it did not, and the
  /// deviceId of the camera the browser actually opened.
  static Future<(bool, String?, String?)> startCameraDevice(
      String videoElementId, {String? deviceId, String facingMode = 'environment'}
      ) async
  {
    try {
      final result = await _startCamera(videoElementId, deviceId, facingMode).toDart;
      final tuple = result.toDart;
      return (
        (tuple[0] as JSBoolean).toDart,
        (tuple[1] as JSString?)?.toDart,
        (tuple[2] as JSString?)?.toDart,
      );
    } catch (e) {
      return (false, e.toString(), null);
    }
  }

  static void stop() => stopCamera();

  static Future<String?> takePicture() async {
    try {
      final jsString = await _takePicture().toDart;
      return jsString?.toDart;
    } catch (_) {
      return null;
    }
  }
}
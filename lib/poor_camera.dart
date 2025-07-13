import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'poor_camera_platform_interface.dart';

class PoorCamera {
  Future<String?> getPlatformVersion() {
    return PoorCameraPlatform.instance.getPlatformVersion();
  }

  Future<Uint8List?> showCamera(BuildContext context,) async
  {
    return await PoorCameraPlatform.instance.showCamera(
        context,
    );
  }

}

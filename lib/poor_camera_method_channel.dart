import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'poor_camera_platform_interface.dart';

/// An implementation of [PoorCameraPlatform] that uses method channels.
class MethodChannelPoorCamera extends PoorCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('poor_camera');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Uint8List?> showCamera(BuildContext context, {void Function(Uint8List? p1)? onImageTaken}) {
    // TODO: implement showCamera
    throw UnimplementedError();
  }
}

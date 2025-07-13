import 'dart:typed_data';

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poor_camera/poor_camera.dart';
import 'package:poor_camera/poor_camera_platform_interface.dart';
import 'package:poor_camera/poor_camera_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPoorCameraPlatform
    with MockPlatformInterfaceMixin
    implements PoorCameraPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List?> showCamera(BuildContext context, {void Function(Uint8List? p1)? onImageTaken}) {
    // TODO: implement showCamera
    throw UnimplementedError();
  }
}

void main() {
  final PoorCameraPlatform initialPlatform = PoorCameraPlatform.instance;

  test('$MethodChannelPoorCamera is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPoorCamera>());
  });

  test('getPlatformVersion', () async {
    PoorCamera poorCameraPlugin = PoorCamera();
    MockPoorCameraPlatform fakePlatform = MockPoorCameraPlatform();
    PoorCameraPlatform.instance = fakePlatform;

    expect(await poorCameraPlugin.getPlatformVersion(), '42');
  });
}

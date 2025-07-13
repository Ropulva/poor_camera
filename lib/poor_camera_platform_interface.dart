import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'poor_camera_method_channel.dart';

abstract class PoorCameraPlatform extends PlatformInterface {
  /// Constructs a PoorCameraPlatform.
  PoorCameraPlatform() : super(token: _token);

  static final Object _token = Object();

  Future<Uint8List?> showCamera(BuildContext context,);
  static PoorCameraPlatform _instance = MethodChannelPoorCamera();

  /// The default instance of [PoorCameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelPoorCamera].
  static PoorCameraPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PoorCameraPlatform] when
  /// they register themselves.
  static set instance(PoorCameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

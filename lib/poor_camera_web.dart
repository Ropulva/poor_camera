// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:poor_camera/web_camera_service/web_camera_widget.dart';
import 'package:web/web.dart' as web;
import 'poor_camera_platform_interface.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

/// A web implementation of the PoorCameraPlatform of the PoorCamera plugin.
class PoorCameraWeb extends PoorCameraPlatform {
  /// Constructs a PoorCameraWeb
  PoorCameraWeb(){
    _registerView();
  }
  final String viewType = 'camera-video-html';
  final String videoElementId = 'cameraVideo';
  void _registerView(){
    final loaded = ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final video = html.VideoElement()
        ..id = videoElementId
        ..autoplay = true
        ..muted = true
        ..style.border = '1px solid black'
        ..width = 300
        ..height = 400
        ..setAttribute('playsinline', 'true');
      //..setAttribute('webkit-playsinline', 'true')
      return video;
    });
  }

  static void registerWith(Registrar registrar) {
    PoorCameraPlatform.instance = PoorCameraWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<Uint8List?> showCamera(BuildContext context, ) async {
    return await showModalBottomSheet<Uint8List?>(
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.black,
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        minWidth: 320,
        //minHeight: MediaQuery.of(context).size.height,
      ),
      builder: (BuildContext context) {
        return PoorCameraWebWidget(
        );
      },
    );
  }

}

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:poor_camera/enums/enums.dart';
import 'package:poor_camera/web_camera_service/web_keys.dart';
import 'package:poor_camera/widgets/icon_button.dart';
import 'camera_service.dart';

const _environment = 'environment';
const _user = 'user';

class PoorCameraWebWidget extends StatefulWidget {
  const PoorCameraWebWidget({super.key, this.onImageTaken});
  final void Function(Uint8List? bytes)? onImageTaken;

  @override
  State<PoorCameraWebWidget> createState() => _PoorCameraWebWidgetState();
}


class _PoorCameraWebWidgetState extends State<PoorCameraWebWidget> {
  List<CameraInfo> _cameras = [];
  RequestState _cameraStarted = RequestState.loading;
  String? _errorMessage;
  /// The camera last requested; kept on failure so retry and switch know
  /// which camera the user was trying to open.
  String? _deviceId;
  String _facingMode = _environment;
  /// Lets a newer start request discard the result of an older one.
  int _requestId = 0;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCamera(facingMode: _environment);
    });
  }

  Future<void> _startCamera({String? deviceId, required String facingMode}) async {
    final requestId = ++_requestId;
    setState(() {
      _cameraStarted = RequestState.loading;
      _errorMessage = null;
      _deviceId = deviceId;
      _facingMode = facingMode;
    });

    final (success, error, activeDeviceId) = await CameraService.startCameraDevice(
      WebKeys.videoElementId,
      deviceId: deviceId,
      facingMode: facingMode,
    );
    if (!mounted || requestId != _requestId) return;

    // Device ids and labels are only exposed once the browser has granted access,
    // and some browsers hide labels while no stream is live, so re-enumerate
    // until at least one camera reports its facing.
    final hasKnownFacing = _cameras.any((c) => _isKnownFacing(c.facingMode.toDart));
    final cameras = hasKnownFacing ? _cameras : await CameraService.fetchAvailableCameras();
    if (!mounted || requestId != _requestId) return;

    setState(() {
      _cameras = cameras;
      if (success) {
        _deviceId = activeDeviceId ?? deviceId;
        _facingMode = _facingOf(_deviceId) ?? facingMode;
        _cameraStarted = RequestState.success;
      } else {
        _errorMessage = _describeError(error);
        _cameraStarted = RequestState.error;
      }
    });
  }

  void _retry() => _startCamera(deviceId: _deviceId, facingMode: _facingMode);

  /// Jumps to the first camera facing the other way, so phones with several
  /// back lenses don't make the user cycle through all of them.
  void _switchCamera() {
    final currentFacing = _facingOf(_deviceId) ?? _facingMode;
    final targetFacing = currentFacing == _user ? _environment : _user;

    final candidates = _cameras.where((c) => c.facingMode.toDart == targetFacing);
    if (candidates.isNotEmpty) {
      _startCamera(deviceId: candidates.first.deviceId.toDart, facingMode: targetFacing);
      return;
    }

    final hasUnlabelledCameras = _cameras.length > 1 &&
        _cameras.every((c) => !_isKnownFacing(c.facingMode.toDart));
    if (hasUnlabelledCameras) {
      final index = _cameras.indexWhere((c) => c.deviceId.toDart == _deviceId);
      final next = _cameras[(index + 1) % _cameras.length];
      _startCamera(deviceId: next.deviceId.toDart, facingMode: targetFacing);
      return;
    }

    _startCamera(facingMode: targetFacing);
  }

  String? _facingOf(String? deviceId) {
    if (deviceId == null) return null;
    for (final camera in _cameras) {
      if (camera.deviceId.toDart == deviceId) {
        final facing = camera.facingMode.toDart;
        return _isKnownFacing(facing) ? facing : null;
      }
    }
    return null;
  }

  bool _isKnownFacing(String facing) => facing == _user || facing == _environment;

  String _describeError(String? error) {
    final message = error ?? '';
    if (message.contains('NotAllowedError') || message.contains('SecurityError')) {
      return 'Camera permission denied. Allow camera access in your browser site settings';
    }
    if (message.contains('NotReadableError') || message.contains('AbortError')) {
      return 'Camera is in use by another app or could not be started';
    }
    if (message.contains('NotFoundError') || message.contains('OverconstrainedError')) {
      return 'Camera not available';
    }
    return message.isEmpty ? 'Camera could not be started' : message;
  }

  Future<void> _takePicture() async {
    final image = await CameraService.takePicture();
    if (!mounted) return;
    try {
      if (image == null) throw const FormatException();
      final bytes = base64Decode(image.split(',').last);
      setState(() => imageBytes = bytes);
    } on FormatException {
      setState(() {
        _errorMessage = 'Could not take the picture';
        _cameraStarted = RequestState.error;
      });
    }
  }

  double get sh => MediaQuery.of(context).size.height ;
  double get sw => MediaQuery.of(context).size.width ;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Positioned(
              top: 10,
              child: _buildView(),
          ),
          if(_cameraStarted == RequestState.loading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 5,
              ),
            )
          else if(_cameraStarted == RequestState.error)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: ${_errorMessage??''} \n'
                          'Refresh to try again',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    PoorIconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _retry
                    ),
                  ],
                ),
              ),
            ),
          if (imageBytes != null)...[
            Align(
              alignment: AlignmentDirectional.topCenter,
              child: Image.memory(
                imageBytes!,
                width: sw,
                height: sh* 0.8,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 50,
              child: Container(
                width: sw,
                color: Colors.black,
                alignment:  AlignmentDirectional.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 100,
                  children: [
                    PoorIconButton(
                        icon: Icon(Icons.done),
                        onPressed: ()async{
                          widget.onImageTaken?.call(imageBytes);
                          Navigator.pop(context,imageBytes);
                        }
                    ),
                    PoorIconButton(
                        icon: Icon(Icons.close),
                        onPressed: ()async{
                          setState(() {
                            imageBytes = null;
                          });
                        }
                    ),
                  ],
                ),
              ),
            ),
          ]
          else
            Positioned(
              bottom: 50,
              child: Container(
                color: Colors.black,
                width: sw,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 50,
                  children: [
                    PoorIconButton(
                        icon: Icon(Icons.cameraswitch),
                        onPressed: _switchCamera
                    ) ,
                    PoorIconButton(
                        icon: Icon(Icons.circle_outlined),
                        width: 50,
                        onPressed: _cameraStarted == RequestState.success ? _takePicture : null
                    ),
                    PoorIconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildView(){
    return SizedBox(
      width: sw,
      height: sh * 0.8,
      child: HtmlElementView(viewType: WebKeys.viewType),
    );
  }

  @override
  void dispose() {
    CameraService.stop();
    super.dispose();
  }
}

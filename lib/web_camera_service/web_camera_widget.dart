import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:poor_camera/enums/enums.dart';
import 'package:poor_camera/web_camera_service/web_keys.dart';
import 'package:poor_camera/widgets/icon_button.dart';
import 'camera_service.dart';

// @JS('requestCameraPermission')
// external JSPromise<JSBoolean> requestCameraPermission();


class PoorCameraWebWidget extends StatefulWidget {
  const PoorCameraWebWidget({super.key, this.onImageTaken});
  final void Function(Uint8List? bytes)? onImageTaken;

  @override
  State<PoorCameraWebWidget> createState() => _PoorCameraWebWidgetState();
}


class _PoorCameraWebWidgetState extends State<PoorCameraWebWidget> {
  List<CameraInfo> _cameras = [];
  RequestState _cameraStarted = RequestState.loading;
  String? _imageBase64;
  String? _errorMessage;
  CameraInfo? _selectedCamera;
  bool _imageTaken = false;

  @override
  void initState() {
    super.initState();
    _initCameraList();
  }

  Future<void> _initCameraList() async {
    try{
      setState(() {
        _cameraStarted = RequestState.loading;
      });
      final cameras = await CameraService.fetchAvailableCameras();
      setState(() {
        _cameraStarted = RequestState.loading;
        _cameras = cameras;
        if (_cameras.isNotEmpty) {
          _selectedCamera = _cameras.first ;
        }
      });

      if (_selectedCamera != null) {
        await _startCameraWithSelected();
      }

    }catch(e){
      _errorMessage = e.toString();
      _cameraStarted = RequestState.error;
      setState(() {});
    }

  }


  Future<void> _startCameraWithSelected() async {
   if(  _cameraStarted != RequestState.loading){
     setState(() {  _cameraStarted = RequestState.loading;});
   }
    if (_selectedCamera == null) return;
    final (success, error) = await CameraService.startCameraDevice(
      WebKeys.videoElementId,
      deviceId: _selectedCamera!.deviceId.toDart,
      facingMode: _selectedCamera!.facingMode.toDart,
    );
    setState(() {
      _cameraStarted = success? RequestState.success : RequestState.error;
      _errorMessage = error;
    });
   print('switching to  ${_selectedCamera?.label.toDart}');
  }

  void _clearCamera() {
    if(mounted) {
      setState(() {
      _imageBase64 = null;
    });
    }
  }

  Future<void> _takePicture() async {
    final image = await CameraService.takePicture();
    setState(() {
      _imageBase64 = image;
      if (_imageBase64 != null) {
        final base64String = _imageBase64!.split(',').last;
        imageBytes = base64Decode(base64String);
        _imageTaken = true;
      }
    });
  }
  double get sh => MediaQuery.of(context).size.height ;
  double get sw => MediaQuery.of(context).size.width ;
  Uint8List? imageBytes;

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
             // alignment: AlignmentDirectional.topCenter,
              child: _buildView()
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
                      'Error: $_errorMessage \n'
                          'Refresh to try again',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    PoorIconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _initCameraList
                    ),
                  ],
                ),
              ),
            ),
          if (_imageTaken && imageBytes != null)...[
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
                            _imageTaken = false;
                            imageBytes = null;
                          });
                        }
                    ),
                  ],
                ),
              ),
            ),
          ]
          else if(_cameraStarted == RequestState.success) ...[
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
                        onPressed: (){
                          //print('_cameras.length ${_cameras.length} -- '
                           //   '${_cameras.map((c) => c.label.toDart).toList()}');
                          if(_cameras.length > 1 ){

                            final index = _cameras.indexOf(_selectedCamera!);
                            CameraService.stop();
                            final next = index == 0 ? 1 : 0 ;
                            setState(() {
                             // print('switching to $next - ${_cameras[next].label.toDart}');
                              _selectedCamera = _cameras[next];
                            });
                            _startCameraWithSelected();
                          }
                        }
                    ) ,
                    PoorIconButton(
                        icon: Icon(Icons.circle_outlined),
                        width: 50,
                        onPressed: _takePicture
                    ),
                    PoorIconButton(
                        icon: Icon(Icons.close),
                        onPressed: (){
                          if(_imageTaken){
                            _clearCamera();
                          }
                          else{
                            Navigator.pop(context);
                          }
                        }
                    ),
                  ],
                ),
              ),
            )
          ],
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
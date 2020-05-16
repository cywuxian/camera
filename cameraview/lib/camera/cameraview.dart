import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cameraview/camera/focus_widget.dart';
import 'package:cameraview/camera/orientation_icon.dart';
import 'package:cameraview/camera/rotate_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'bloccamera.dart';
enum CameraOrientation { landscape, portrait, all }
enum CameraMode { fullscreen, normal }
class CameraView extends StatefulWidget{
  final Widget imageMask;
  final CameraMode mode;
  final Widget warning;
  final CameraOrientation orientationEnablePhoto;
  final Function(File image) onFile;
  const CameraView(
      {Key key,
        this.imageMask,
        this.mode = CameraMode.fullscreen,
        this.orientationEnablePhoto = CameraOrientation.all,
        this.onFile,
        this.warning})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _CameraView();
  }
}
class _CameraView extends State<CameraView>{
  var bloc = BlocCamera();
  var previewH;
  var previewW;
  var screenRatio;
  var previewRatio;
  Size tmp;
  Size sizeImage;

  @override
  void initState() {
    super.initState();
    bloc.getCameras();
    bloc.cameras.listen((data) {
      bloc.controllCamera = CameraController(
        data[1],
        ResolutionPreset.high,
      );
      bloc.cameraOn.sink.add(0);
      bloc.controllCamera.initialize().then((_) {
        bloc.selectCamera.sink.add(true);
      });
    });
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    bloc.start();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
    bloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Size sizeImage = size;
    double width = size.width;
    double height = size.height;

    return NativeDeviceOrientationReader(
      useSensor: true,
      builder: (context) {
        NativeDeviceOrientation orientation =
        NativeDeviceOrientationReader.orientation(context);

        _buttonPhoto() => CircleAvatar(
          child: IconButton(
            icon: OrientationWidget(
              orientation: orientation,
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              sizeImage = MediaQuery.of(context).size;
              bloc.onTakePictureButtonPressed();
            },
          ),
          backgroundColor: Colors.black38,
          radius: 25.0,
        );

        Widget _getButtonPhoto() {
          if (widget.orientationEnablePhoto == CameraOrientation.all) {
            return _buttonPhoto();
          } else if (widget.orientationEnablePhoto ==
              CameraOrientation.landscape) {
            if (orientation == NativeDeviceOrientation.landscapeLeft ||
                orientation == NativeDeviceOrientation.landscapeRight)
              return _buttonPhoto();
            else
              return Container(
                width: 0.0,
                height: 0.0,
              );
          } else {
            if (orientation == NativeDeviceOrientation.portraitDown ||
                orientation == NativeDeviceOrientation.portraitUp)
              return _buttonPhoto();
            else
              return Container(
                width: 0.0,
                height: 0.0,
              );
          }
        }

        if (orientation == NativeDeviceOrientation.portraitDown ||
            orientation == NativeDeviceOrientation.portraitUp) {
          sizeImage = Size(width, height);
        } else {
          sizeImage = Size(height, width);
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Stack(
              children: <Widget>[
                Center(
                  child: StreamBuilder<File>(
                      stream: bloc.imagePath.stream,
                      builder: (context, snapshot) {
                       return Stack(
                          children: <Widget>[
                            Center(
                              child: StreamBuilder<bool>(
                                  stream: bloc.selectCamera.stream,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data) {
                                        previewRatio = bloc
                                            .controllCamera.value.aspectRatio;

                                        return widget.mode ==
                                            CameraMode.fullscreen
                                            ? OverflowBox(
                                          maxHeight: size.height,
                                          maxWidth: size.height *
                                              previewRatio,
                                          child: CameraPreview(
                                              bloc.controllCamera),
                                        )
                                            : AspectRatio(
                                          aspectRatio: bloc
                                              .controllCamera
                                              .value
                                              .aspectRatio,
                                          child: CameraPreview(
                                              bloc.controllCamera),
                                        );
                                      } else {
                                        return Container();
                                      }
                                    } else {
                                      return Container();
                                    }
                                  }),
                            ),
                            FocusCircle(color:this.bloc.color)
                          ],
                        );
                      }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:cameraview/camera/encode_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:json_annotation/json_annotation.dart';

import 'face_request_repository.dart';

class BlocCamera {
  var cameras = BehaviorSubject<List<CameraDescription>>();
  var selectCamera = BehaviorSubject<bool>();
  var imagePath = BehaviorSubject<File>();
  var cameraOn = BehaviorSubject<int>();
  var _timer;
  var color = Colors.white;
  CameraController controllCamera;


    Future start({int seconds = 5}) async{//5秒后开始获取
   _timer = Timer.periodic(Duration(seconds: seconds), (timer){
     this.color = Colors.red;
     this.start(seconds:3);
     if(seconds == 5){
       onTakePictureButtonPressed();
     }
     _timer?.cancel();
    });
  }
  Future getCameras() async {
    await availableCameras().then((lista) {
      cameras.sink.add(lista);
    }).catchError((e) {
      print("ERROR CAMERA: $e");
    });
  }

  Future<String> takePicture() async {
    if (!controllCamera.value.isInitialized) {
      print("selecionado camera");
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controllCamera.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controllCamera.takePicture(filePath);
    } on CameraException catch (e) {
      print(e);
      return null;
    }
    return filePath;
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onTakePictureButtonPressed() async{
    takePicture().then((String filePath) {
//      imagePath.sink.add(File(filePath));
      checkImageStatus(filePath);
    });
  }
 void checkImageStatus(String filePath) async{
   String accessToken = await FaceRequestRepository.getToken(clientId: 'aFAaY0Dx78U7f7LIzoelrVPW', clientSecret: '22oMlDDN6lFG6dWDfXVRXzMsjG2VTYjl');
     if(accessToken != null){
       String data = await EncodeUtil.image2Base64(filePath);
       try{
         Response response = await FaceRequestRepository.checkFaceStatus(accessToken: accessToken, data: data);
         if(response.data['error_code'] == 0){
           //成功
           print(response.data['result']["face_list"]);
         }else if(response.data['error_code'] == 222202){
           //	图片中没有人脸
//           onTakePictureButtonPressed();//如果验证失败重新获取图片
         }else if(response.data['error_code'] == 222203){
           //无法解析人脸
//           onTakePictureButtonPressed();//如果验证失败重新获取图片
         }
       }catch(e,f){

       }
     }
 }
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    selectCamera.sink.add(null);
    if (controllCamera != null) {
      await controllCamera.dispose();
    }
    controllCamera =
        CameraController(cameraDescription, ResolutionPreset.medium);
    controllCamera.addListener(() {
      if (controllCamera.value.hasError) selectCamera.sink.add(false);
    });

    await controllCamera.initialize().then((value) {
      selectCamera.sink.add(true);
    }).catchError((e) {
      print(e);
    });
  }

  void changeCamera() {
    var list = cameras.value;
    if (list.length == 2) {
      if (controllCamera.description.lensDirection ==
          CameraLensDirection.back) {
        onNewCameraSelected(list[1]);
        cameraOn.sink.add(1);
      } else {
        onNewCameraSelected(list[0]);
        cameraOn.sink.add(0);
      }
    }
  }

  void deletePhoto() {
    var dir = new Directory(imagePath.value.path);
    dir.deleteSync(recursive: true);
    imagePath.sink.add(null);
  }

  void dispose() {
    cameras.close();
    controllCamera.dispose();
    selectCamera.close();
    imagePath.close();
    cameraOn.close();
  }
}

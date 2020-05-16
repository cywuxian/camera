import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class FaceRequestRepository{
  //获取百度授权
 static Future<String> getToken({@required String clientId,@required String clientSecret}) async{
    String host ="https://aip.baidubce.com/oauth/2.0/token?";
    String uri = host+"grant_type=client_credentials&"+"client_id="+clientId+"&client_secret="+clientSecret;
    var responseBody;
    var httpClient = new HttpClient();
    var request = await  httpClient.getUrl(Uri.parse(uri));
    var response = await request.close();
    if (response.statusCode == 200) {
      responseBody = await response.transform(utf8.decoder).join();
      var  json = jsonDecode(responseBody.toString());
      print(json["access_token"]);
      return json["access_token"];
    }else{
      print("error");
      return null;
    }
  }
  //人脸识别查询
static Future<Response> checkFaceStatus({@required String accessToken,
  @required String data,
  String imageType = "BASE64",
  String livenessControl = "NORMAL",
  String face_type =""
}) async {
  Response response = await Dio().request(
        'https://aip.baidubce.com/rest/2.0/face/v3/detect?access_token='+accessToken,
      options: Options(
        method: 'post',
        headers: {
          'Content-Type':'application/json'
        }
      ),
        data: {
          "image":data,
          "image_type":imageType,
          "liveness_control":livenessControl
    }
    );
  return response;
}
}
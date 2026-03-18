import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';


// esta clase con el paquete nos ayuda a obtener la info del dispositivo para
// enviarselo al backend analitico, resuelve parte de la bq1
class DeviceInfoService {
  String deviceModel = '';
  String platform = '';
  String osVersion = '';

  Future<void> init() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      deviceModel = ios.utsname.machine;
      platform = 'ios';
      osVersion = ios.systemVersion;
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      deviceModel = android.model;
      platform = 'android';
      osVersion = android.version.release;
    }
  }
}

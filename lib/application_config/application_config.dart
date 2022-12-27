import 'dart:convert';

class ApplicationConfig{
  static String currentVersion = "1.1.0";

  Future<void> _checkForUpdate() async{
    final jsonVal = await loadJson();
  }

  loadJson(){
    return jsonDecode("app_version_check/version.json");
  }
}
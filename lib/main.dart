import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_app_update_for_windows_example/application_config/application_config.dart';
import 'package:flutter_in_app_update_for_windows_example/version.dart';
import 'package:folivora_http/folivora_http.dart';
import 'package:path_provider/path_provider.dart';

import 'theme_view_model.dart';

void main() {
  runApp(ThemeViewModel(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemeViewModel.of(context)!.theme,
      builder: (BuildContext context, ThemeData themeData, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeData,
          home: const MyHomePage(title: 'In App Update for Windows'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isDownloading = false;
  double downloadProgress = 0;
  String downloadFilePath = "";

  Future<Map<String, dynamic>> loadJson() async {
    Map<String, dynamic> json = jsonDecode(
        await rootBundle.loadString("app_version_check/version.json"));
    return json;
  }

  Future<void> openExeFile(String filePath) async {
    await Process.start(filePath, ["-t", "-l", "1000"]).then((value) => {});
  }

  Future<void> downloadNewVersion(String filePath) async {
    final String fileName = filePath.split("/").last;
    isDownloading = true;
    setState(() {});

    downloadFilePath = "${(await getTemporaryDirectory()).path}/$fileName";

    Dio dio = Dio();
    await dio.download(
        filePath,
        downloadFilePath, onReceiveProgress: (received, total) {
      final progress = (received / total) * 100;
      debugPrint("Rec: $received, Total: $total, $progress%");
      downloadProgress = double.parse(progress.toStringAsFixed(1));
      setState(() {});
    });

    debugPrint("File Downloaded Path: $downloadFilePath");
    await openExeFile(downloadFilePath);

    isDownloading = false;

    setState(() {});
  }

  showUpdateDialog(Version version) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(8),
            title: Text("Latest Version ${version.version}"),
            children: [
              Text("What's new in ${version.version}"),
              const SizedBox(
                height: 4,
              ),
              if (version.version != ApplicationConfig.currentVersion)
                TextButton.icon(
                    onPressed: () {
                      downloadNewVersion("${version.repositoryUrl}/${version.filePath!}");
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.update),
                    label: const Text("Update")),
            ],
          );
        });
  }

  Future<void> _checkForUpdate() async {
    final Map<String, dynamic> json = await loadJson();

    Version version = Version();
    version.version = json['version'];
    version.description = (json['description'] as List<dynamic>).map((e) => e as String).toList();
    version.filePath = json['file_path'];
    version.repositoryUrl = json['repository_url'];

    debugPrint("Response: $version");
    showUpdateDialog(version);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _checkForUpdate();
        },
        child: const Icon(Icons.update),
      ),
      body: Center(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Current Version is ${ApplicationConfig.currentVersion}"),
                if (!isDownloading && downloadFilePath != "")
                  Text("File Downloaded in $downloadFilePath"),
              ],
            ),
            if (isDownloading)
              Container(
                width: 200,
                height: 200,
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    Text("${downloadProgress.toStringAsFixed(1)}%"),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

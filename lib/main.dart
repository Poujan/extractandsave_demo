import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DownloadAssetsDemo(),
    );
  }
}

class DownloadAssetsDemo extends StatefulWidget {
  const DownloadAssetsDemo({super.key});

  final String title = "Download & Extract ZIP Demo";

  @override
  DownloadAssetsDemoState createState() => DownloadAssetsDemoState();
}

class DownloadAssetsDemoState extends State<DownloadAssetsDemo> {
  //
  late bool _downloading;
  String? _dir;
  String? _dirStorage;
  List<String>? _pdf, _tempPDF;
  final String _zipPath =
      'https://selfcareapi.telecom.mu/technical/clm/6311507/invoice-statements';
  final String _localZipFileName = 'zipFile.zip';

  getHistoryPDFList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _pdf = prefs.getStringList("PDF");
    });
  }

  @override
  void initState() {
    super.initState();
    _pdf = [];
    getHistoryPDFList();
    _tempPDF = [];
    _downloading = false;
    _initDir();
    _downloadZip();
    _initDirStorage();
  }

  _initDir() async {
    // ignore: unnecessary_null_comparison
    if (_dir == null) {
      _dir = (await getApplicationDocumentsDirectory()).path;
      print("init $_dir");
    }
  }

  _initDirStorage() async {
    // ignore: unnecessary_null_comparison
    if (_dirStorage == null) {
      _dirStorage = (await DownloadsPathProvider.downloadsDirectory)!.path;
      print("initStorage $_dirStorage");
    }
  }

  Future<File> _downloadFile(String url, String fileName) async {
    var req = await http.Client().get(Uri.parse(url));
    var file = File('$_dir/$fileName');
    print("file.path ${file.path}");
    return file.writeAsBytes(req.bodyBytes);
  }

  Future<File> _downloadFileStorage(String url, String fileNameStorage) async {
    var req = await http.Client().get(Uri.parse(url));
    var fileStorage = File('$_dirStorage/$fileNameStorage');
    print("file.path ${fileStorage.path}");
    return fileStorage.writeAsBytes(req.bodyBytes);
  }

  Future<void> _downloadZip() async {
    setState(() {
      _downloading = true;
    });

    _pdf?.clear();
    _tempPDF?.clear();

    var zippedFile = await _downloadFile(_zipPath, _localZipFileName);
    await unarchiveAndSave(zippedFile);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("pdf", _tempPDF!);
    setState(() {
      _pdf = List<String>.from(_tempPDF!);
      _downloading = false;
    });
  }

  Future<void> _downloadZipStorage() async {
    setState(() {
      _downloading = true;
    });

    var zipfile1 = await _downloadFileStorage(_zipPath, _localZipFileName);
    await unzipandsave(zipfile1);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("pdf", _tempPDF!);
    setState(() {
      _pdf = List<String>.from(_tempPDF!);
      _downloading = false;
    });
  }

  unarchiveAndSave(var zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$_dir/${file.name}';
      print("fileName $fileName");
      if (file.isFile && !fileName.contains("__MACOSX")) {
        var outFile = File(fileName);
        // ignore: prefer_interpolation_to_compose_strings

        _tempPDF?.add(outFile.path);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
  }

  unzipandsave(var zipfile) async {
    var bytes = zipfile.readAsBytesSync();
    var inarchive = ZipDecoder().decodeBytes(bytes);
    for (var file in inarchive) {
      var fileName = '$_dirStorage/${file.name}';
      print("fileName $fileName");
      if (file.isFile && !fileName.contains("__MACOSX")) {
        var outFile = File(fileName);
        // ignore: prefer_interpolation_to_compose_strings
        print('filename::: $outFile');
        _tempPDF?.add(outFile.path);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
  }

  buildList() {
    return _pdf == null
        ? Container()
        : ListView.builder(
            itemCount: _pdf?.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  Center(
                    child: Card(
                      color: Colors.white,
                      child: SizedBox(
                        width: MediaQuery.maybeOf(context)!.size.width,
                        height: 540,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: SfPdfViewer.file(
                            File(_pdf![index]),
                            // canShowScrollHead: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }

  // progress() {
  //   return Container(
  //     width: 25,
  //     height: 25,
  //     padding: const EdgeInsets.fromLTRB(0.0, 20.0, 10.0, 20.0),
  //     child: const CircularProgressIndicator(
  //       strokeWidth: 3.0,
  //       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 400,
                height: 650,
                child: buildList(),
              ),
              ElevatedButton(
                  onPressed: () {
                    _downloadZipStorage();
                  },
                  child: const Text("Download PDF")),
            ],
          ),
        ),
      ),
    );
  }
}

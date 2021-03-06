import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'preview_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = true;
  bool _isRecording = false;
  late CameraController _cameraController;
  Duration duration = const Duration(seconds: 0);
  late double finaltime;
  late String datetime;
  Timer? timer;

  @override
  void initState() {
    _initCameraServices();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      timer =
          Timer.periodic(const Duration(milliseconds: 1), (_) => increment());
    });
  }

  void increment() {
    const add = 1;
    setState(() {
      if (_isRecording) {
        final milliseconds = duration.inMilliseconds + add;
        duration = Duration(milliseconds: milliseconds);
      }
    });
  }

  void resetTimer() {
    timer?.cancel();
    duration = const Duration(seconds: 0);
  }

  _initCameraServices() async {
    final cameras = await availableCameras();

    _cameraController = CameraController(
        cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back),
        ResolutionPreset.max);
    await _cameraController.initialize();
    setState(() => _isLoading = false);
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
        finaltime = duration.inMilliseconds / 1000;
        final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PreviewPage(
              filePath: file.path, duration: finaltime, datetime: datetime),
        );
        Navigator.push(context, route);
        resetTimer();
      });
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      datetime = DateTime.now().toDateTimeIso8601String();
      startTimer();
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Video'),
      ),
      body: Container(
        child: _isLoading
            ?
            //Camera has not loaded, prompt user to wait //TODO This should be initiated earlier
            Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            :
            //Camera has loaded, display view and guides
            Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                      widthFactor: 1, child: CameraPreview(_cameraController)),
                  const Positioned.fill(
                    right: 260,
                    child: VerticalDivider(
                      width: 10,
                      thickness: 3,
                      indent: 10,
                      endIndent: 120,
                      color: Colors.green,
                    ),
                  ),
                  const Positioned.fill(
                    left: 260,
                    child: VerticalDivider(
                      width: 10,
                      thickness: 3,
                      indent: 10,
                      endIndent: 120,
                      color: Colors.red,
                    ),
                  ),
                  const Positioned(
                      child: Text(
                        '-------10ft-------',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 30,
                          decoration: TextDecoration.none,
                        ), //Gets rid of yellow lines
                      ),
                      bottom: 160),
                  const Positioned.fill(
                    top: 210,
                    child: Divider(
                      height: 10,
                      thickness: 3,
                      indent: 60,
                      endIndent: 60,
                      color: Colors.orange,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Text(
                      'Duration: ${(duration.inMilliseconds / 1000).round()} sec',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 30,
                          decoration:
                              TextDecoration.none), //Gets rid of yellow lines
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FloatingActionButton(
            backgroundColor: Colors.blue,
            child: Icon(_isRecording ? Icons.stop : Icons.circle),
            onPressed: () => _recordVideo(),
          ),
        ]),
        color: Colors.blue,
      ),
    );
  }
}

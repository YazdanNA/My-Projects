import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:video_player_trimmer/video_player_page.dart';
import 'package:video_trimmer/video_trimmer.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {super.key});

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();
  String? savePath;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveVideo(BuildContext context) async {
    _trimmer.videoPlayerController?.pause();
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) async {
        setState(() {
          _progressVisibility = false;
        });

        String? name = await _getNameOfVideo();
        if (name != "") {
          var path = await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOADS);

          if (await File("$path/$name.mp4").exists()) {
            _showErrorAlert(
                "A file with this name already exists", "Error", "error");
          } else {
            if (outputPath == null || outputPath == "") {
              return _showErrorAlert(
                  "An error occurred, please try later", "Error", "error");
            }
            try {
              File file = File(outputPath);
              var read = file.openRead();

              var newFile =
                  await File("$path/$name.mp4").create(recursive: false);
              showProgress(true);
              var sink = newFile.openWrite();
              await for (List<int> readAsStream in read) {
                sink.add(readAsStream);
              }

              await sink.close();

              showProgress(false);

              _showErrorAlert(
                  "${newFile.path}\n Saved successfully", "Info", "save",
                  trimmed: "$path/$name.mp4", main: widget.file.path);
            } catch (e) {
              _showErrorAlert(e.toString(), "Error", "error");
            }
          }
        } else {
          _showErrorAlert("The file name cannot be empty", "Error", "error");
        }
      },
    );
  }

  void canPop() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Are you sure?',
              style: TextStyle(color: Colors.white), textAlign: TextAlign.end),
          content: const Text('The changes will be lost',
              style: TextStyle(color: Colors.white), textAlign: TextAlign.end),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showProgress(bool show) {
    if (show) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Colors.black87,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Saving...',
                  style: TextStyle(color: Colors.white),
                ),
                CircularProgressIndicator(),
              ],
            ),
          );
        },
        barrierDismissible: false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _loadVideo() {
    try {
      _trimmer.loadVideo(videoFile: widget.file);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorAlert(e.toString(), "Error", "error");
      });
    }
  }

  Future<String?> _getNameOfVideo() {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 1,
            child: AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text(
                "Save file",
                textAlign: TextAlign.end,
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                children: [
                  const Text(
                    'Please enter the name of file',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.white),
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    controller: _nameController,
                    // inputFormatters: [
                    //   FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    // ],
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: false,
                        focusColor: Colors.white,
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white),
                        counterStyle: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              actions: [
                // Expanded(
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, _nameController.text);
                  },
                  child:
                      const Text('Ok', style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
      },
      barrierDismissible: false,
    );
  }

  void _showErrorAlert(String errorMessage, String title, String kind,
      {String trimmed = "", String main = ""}) {
    switch (kind) {
      case "error":
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: Text(
                title,
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(errorMessage,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ok'),
                ),
              ],
            );
          },
          barrierDismissible: false,
        );
        break;

      case "save":
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: Text(
                title,
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(errorMessage,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MyVideoPlayer(file: File(trimmed))),
                      (route) => false,
                    );
                  },
                  child: const Text('Play trimmed video'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                MyVideoPlayer(file: File(main))),
                        (route) => false);
                  },
                  child: const Text('Play original video'),
                ),
              ],
            );
          },
          barrierDismissible: false,
        );
    }
  }

  @override
  void initState() {
    super.initState();

    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
          canPop();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: const Color.fromRGBO(0, 0, 0, 20),
            actions: [
              IconButton(
                  color: Colors.white,
                  onPressed: _progressVisibility
                      ? null
                      : () async {
                          await _saveVideo(context);
                        },
                  icon: const Icon(Icons.save_alt))
            ],
          ),
          body: Builder(
            builder: (context) => Center(
                child: Container(
              padding: const EdgeInsets.only(bottom: 30.0),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Visibility(
                    visible: _progressVisibility,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: VideoViewer(trimmer: _trimmer),
                  ),
                  Center(
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      maxVideoLength: const Duration(minutes: 200),
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) =>
                          setState(() => _isPlaying = value),
                    ),
                  ),
                  TextButton(
                    child: _isPlaying
                        ? const Icon(
                            Icons.pause,
                            size: 50.0,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.play_arrow,
                            size: 50.0,
                            color: Colors.white,
                          ),
                    onPressed: () async {
                      bool playbackState = await _trimmer.videoPlaybackControl(
                        startValue: _startValue,
                        endValue: _endValue,
                      );
                      setState(() {
                        _isPlaying = playbackState;
                      });
                    },
                  )
                ],
              ),
            )),
          ),
        ));
  }
}

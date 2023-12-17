import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_player_trimmer/video_trimmer_page.dart';



class MyVideoPlayer extends StatefulWidget {


  final File file;
  const MyVideoPlayer({required this.file,super.key});



  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState(file);
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  _MyVideoPlayerState(File file){
    filePath = file.path;
  }
  String filePath ="";
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  double _currentSliderValue = 0.0;
  bool _mediaControlsVisible = true;
  bool _userInteracted = false;
  bool _isWideScreen = false;
  double _playbackSpeed = 1.0;
  String appBarText = "";


  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(filePath));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.addListener(() {
      setState(() {
        _currentSliderValue = _controller.value.position.inSeconds.toDouble();
      });
      if (_controller.value.isPlaying) {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 4)).then((value) {
      if (!_userInteracted) {
        setState(() {
          _mediaControlsVisible = false;
        });
      }
    });
  }
  void _showSpeedPopupMenu(BuildContext context) async {
    double? selectedSpeed = await showMenu<double>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        const PopupMenuItem<double>(
          value: 0.5,
          child: Text('0.5X'),
        ),
        const PopupMenuItem<double>(
          value: 1.0,
          child: Text('1X'),
        ),
        const PopupMenuItem<double>(
          value: 1.5,
          child: Text('1.5X'),
        ),
        const PopupMenuItem<double>(
          value: 2.0,
          child: Text('2X'),
        ),
      ],
      elevation: 8.0,
    );

    if (selectedSpeed != null) {
      setState(() {
        _playbackSpeed = selectedSpeed;
        _changePlaybackSpeed();
      });
    }
  }

  void _changePlaybackSpeed() {
    if (_controller.value.isPlaying) {
      _controller.setPlaybackSpeed(_playbackSpeed);
    }
  }
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }
  void _resetTimer() {
    setState(() {
      _mediaControlsVisible = true;
    });
    _startTimer();
  }
  void _showErrorAlert(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('خطا'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('باشه'),
            ),
          ],
        );
      },
    );
  }

  void _pickVideo() async {
    if (_controller.value.isPlaying) {
      _controller.pause();
    }
    try{

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result != null && result.files.isNotEmpty) {
        filePath = result.files.single.path!;
        if (_controller.value.isPlaying) {
          _controller.pause();
        }
        await _controller.dispose();
        _controller = VideoPlayerController.file(File(filePath))
          ..addListener(() {
            setState(() {
              _currentSliderValue =
                  _controller.value.position.inSeconds.toDouble();
            });
          })
          ..initialize().then((_) {
            setState(() {
              appBarText = result.files.single.name;
            });
          });
      }

    }catch(e){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorAlert(e.toString());
      });
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.isNotEmpty) {
      filePath = result.files.single.path!;
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
      await _controller.dispose();
      _controller = VideoPlayerController.file(File(filePath))
        ..addListener(() {
          setState(() {
            _currentSliderValue =
                _controller.value.position.inSeconds.toDouble();
          });
        })
        ..initialize().then((_) {
          setState(() {
            appBarText = result.files.single.name;
          });
        });
    }
  }

  void _seekToSeconds(double seconds) {
    Duration newDuration = Duration(seconds: seconds.toInt());
    _controller.seekTo(newDuration);
    _resetTimer();
  }

  void _toggleMediaControlsVisibility() {
    setState(() {
      _mediaControlsVisible = !_mediaControlsVisible;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _mediaControlsVisible
          ? AppBar(
        backgroundColor: Color.fromRGBO(0, 0, 0, 25),
        title: Text(
          appBarText,
        style: const TextStyle(
          color: Colors.white70
        ),
        ),
      )
          : null,
      body: GestureDetector(
        onTap: () {

          setState(() {
            if(_mediaControlsVisible){
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack );
            }else{
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual , overlays: SystemUiOverlay.values);
            }
            _userInteracted = true;
            _toggleMediaControlsVisibility();
            if (_mediaControlsVisible) {
              _resetTimer();
            }
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return FittedBox(
                      fit: _isWideScreen ? BoxFit.cover : BoxFit.contain,
                      child: SizedBox(

                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
            AnimatedOpacity(
              opacity: _mediaControlsVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.0), //
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                flex: 3,
                                child: Text(
                                  "${formatDuration(Duration(seconds: _currentSliderValue.toInt()))}",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Flexible(
                                flex: 9,
                                child: Slider(
                                  value: _currentSliderValue,
                                  min: 0.0,
                                  max: _controller.value.duration.inSeconds.toDouble(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _seekToSeconds(value);
                                    });
                                  },
                                ),
                              ),
                              Flexible(
                                flex: 3,
                                child: Text(
                                  "${formatDuration(_controller.value.duration)}",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.fast_rewind),
                              onPressed: () {
                                _seekToSeconds(_currentSliderValue - 10.0);
                              },
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                });
                              },
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.fast_forward),
                              onPressed: () {
                                _seekToSeconds(_currentSliderValue + 10.0);
                              },
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.folder),
                              onPressed: () {
                                _pickVideo();
                              },
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                if (_controller.value.isPlaying) {
                                  _controller.pause();
                                }
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => TrimmerView(File(filePath))),
                                );
                              },
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.aspect_ratio),
                              onPressed: () {
                                setState(() {
                                  _isWideScreen = !_isWideScreen;
                                });
                              },
                            ),IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.speed),
                              onPressed: () {
                                  _showSpeedPopupMenu(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

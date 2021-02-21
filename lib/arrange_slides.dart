import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:just_audio/just_audio.dart';

class ArrangeSlidesPage extends StatefulWidget {
  @override
  _ArrangeSlidesPageState createState() => _ArrangeSlidesPageState();
}

class _ArrangeSlidesPageState extends State<ArrangeSlidesPage>
    with WidgetsBindingObserver {
  AudioPlayer player = AudioPlayer();
  bool loaded = false;
  String audioPath;
  Stream<Duration> positionStream;
  String error = "";
  Map<Duration, String> mapImages = {};
  TextEditingController _controller = TextEditingController();
  Duration duration;

  Duration getMin(Iterable<Duration> values) {
    Duration least = values.first;
    for (Duration value in values) {
      if (value < least) least = value;
    }
    return least;
  }

  String positionString() {
    String pos = player.position.toString();
    pos = pos.substring(0, pos.indexOf("."));
    String total = duration.toString();
    total = total.substring(0, total.indexOf("."));
    return "$pos / $total";
  }

  Duration getCurrent() {
    Duration currentBest = Duration.zero;
    for (Duration d in mapImages.keys) {
      if (d < player.position && d > currentBest) currentBest = d;
    }
    return currentBest;
  }

  double getAudioPosition() {
    if ([ProcessingState.idle, ProcessingState.loading]
        .contains(player.processingState)) return 0;
    return player.position.inMilliseconds / duration.inMilliseconds;
  }

  void pickImage() async {
    bool playing = player.playing;
    player.pause();
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (mapImages.isEmpty)
      mapImages.putIfAbsent(Duration.zero, () => result.files.single.path);
    else
      mapImages.update(player.position, (value) => result.files.single.path,
          ifAbsent: () => result.files.single.path);
    if (playing) player.play();
    setState(() {});
  }

  void loadAudio() async {
    try {
      FilePickerResult result =
          await FilePicker.platform.pickFiles(type: FileType.audio);
      audioPath = result.files.single.path;
      duration = await player.setFilePath(audioPath);
      await player.setLoopMode(LoopMode.one);
      loaded = true;
    } catch (e) {
      error = e.toString();
    }
    setState(() {});
    pickImage();
  }

  void saveAsVideo() {
    print(mapImages);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) player.pause();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadAudio();
    positionStream = player.createPositionStream();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded)
      return Container(
        child: Center(
          child: Text(error),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text("Arrange Slides"),
        leading: IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_rounded),
            onPressed: () {
              if (mapImages.length == 0) return;
              Duration current = getCurrent();
              mapImages.remove(current);
              if (current == Duration.zero) {
                Duration least = getMin(mapImages.keys);
                String temp = mapImages[least];
                mapImages.remove(least);
                mapImages.putIfAbsent(Duration.zero, () => temp);
              }
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.save_alt_rounded),
            onPressed: getName,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: Container(
            padding: EdgeInsets.all(10),
            child: StreamBuilder<Duration>(
              stream: positionStream,
              builder: (context, snapshot) {
                if (mapImages.length > 0)
                  return Image.file(File(mapImages[getCurrent()]));
                return Center(child: Text("Add some images"));
              },
            ),
          )),
          Container(
            child: StreamBuilder<Object>(
                stream: positionStream,
                builder: (context, snapshot) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => player.seek(max(Duration.zero,
                                player.position - Duration(seconds: 5))),
                            icon: Icon(Icons.fast_rewind_rounded),
                          ),
                          IconButton(
                            onPressed: () {
                              player.playing ? player.pause() : player.play();
                              setState(() {});
                            },
                            icon: Icon(
                              player.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Duration newPos =
                                  player.position + Duration(seconds: 5);
                              newPos < duration
                                  ? player.seek(newPos)
                                  : player.seek(duration);
                            },
                            icon: Icon(Icons.fast_forward_rounded),
                          ),
                          Expanded(
                            child: Container(
                              child: Center(
                                child: Text("${positionString()}"),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_rounded),
                            onPressed: () => pickImage(),
                          ),
                        ],
                      ),
                      Slider(
                        value: getAudioPosition(),
                        onChanged: (pos) => player.seek(duration * pos),
                      ),
                    ],
                  );
                }),
            padding: EdgeInsets.all(20),
          ),
        ],
      ),
    );
  }

  void showRes(int rc, BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: rc == 0
              ? Text("Success")
              : Text("Error $rc", style: TextStyle(color: Colors.redAccent)),
          actions: [
            CupertinoDialogAction(
              child: Text("Exit"),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            CupertinoDialogAction(
              child: Text("Continue"),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void loading(name) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    int rc = await saveVideo(name);
    Navigator.of(context, rootNavigator: true).pop();
    showRes(rc, context);
  }

  void getName() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          title: Text("Enter name"),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                textAlignVertical: TextAlignVertical.bottom,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: [
                MaterialButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                MaterialButton(
                  child: Text("Save"),
                  onPressed: () {
                    String name = _controller.value.text;
                    Navigator.of(context, rootNavigator: true).pop();
                    loading(name);
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<int> saveVideo(String name) async {
    Directory directory = Directory("/storage/emulated/0/DCIM/slideshow/");
    // Directory tempDir = await getTemporaryDirectory();
    List<Duration> timestamps = sort(mapImages.keys)..add(duration);

    String command = "-y -r:v 1 -i $audioPath ", subcommand = "";
    for (int i = 0; i < timestamps.length - 1; i++) {
      String time = (timestamps[i + 1] - timestamps[i]).inSeconds.toString();
      command += "-loop 1 -t $time -i ${mapImages[timestamps[i]]} ";
      subcommand += "[${i + 1}:v]";
    }

    command +=
        " -filter_complex \"$subcommand concat=n=${timestamps.length - 1}"
        ":v=1:a=0 [out]\" -map \"[out]\" -map 0:a "
        "-r:v 30 -pix_fmt yuv420p -c:v libx264 ${directory.path}/$name.mp4";

    // command = '-y -f concat -safe 0 -i  -i $audioPath'
    //     ' -vsync vfr -pix_fmt yuv420p -c:v libx264 ${directory.path}/$name.mp4';
    int rc = await FlutterFFmpeg().execute(command);
    //FlutterFFmpeg().cancel();
    return rc;
  }

  List<Duration> sort(Iterable<Duration> timestamps) {
    List<Duration> sorted = [];
    for (Duration d in timestamps) {
      int i = -1;
      while (++i < sorted.length) if (sorted[i] > d) break;
      sorted.insert(i, d);
    }
    return sorted;
  }
}

 /* File txtFile = File(tempDir.path + "/video.txt");
    await txtFile.writeAsString("");
    for (int i = 0; i < timestamps.length - 1; i++) {
      String time = (timestamps[i + 1] - timestamps[i]).inSeconds.toString();
      //time = time.substring(0, time.indexOf("."));
      await txtFile.writeAsString("file '${mapImages[timestamps[i]]}'\n",
          mode: FileMode.append);
      await txtFile.writeAsString("duration $time\n", mode: FileMode.append);
    }
    await txtFile.writeAsString(
        "file '${mapImages[timestamps[timestamps.length - 2]]}'\n",
        mode: FileMode.append); */
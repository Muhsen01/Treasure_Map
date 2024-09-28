import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:treasure_map/picture_screen.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'place.dart';

class CameraScreen extends StatefulWidget {
  @override
  final Place place;
  CameraScreen(this.place);
  _CameraScreenState createState() => _CameraScreenState(this.place);
}

class _CameraScreenState extends State<CameraScreen> {
  final Place place;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late CameraDescription camera;
  late Widget cameraPreview = Container();
  late Image image;

  _CameraScreenState(this.place);

  Future setCamera() async {
    cameras = await availableCameras();
    if (cameras.length != 0)
      camera = cameras.first;
  }

  @override
  void initState() {
    setCamera().then((_) {
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
      );
      _controller.initialize().then((snapshot) {
        cameraPreview = Center(child: CameraPreview(_controller));
        setState(() {
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Take Picture'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                final path = join((await getTemporaryDirectory()).path, '${DateTime.now()}.jpg',);
                // Attempt to take a picture and log where it's been saved.
                await takePicture(context, path);
                MaterialPageRoute route = MaterialPageRoute(
                    builder: (context) => PictureScreen(path, place)
                );
                Navigator.push(context, route);
              },
            )
          ],
        ),
        body: Container(
          child: cameraPreview,
        ));
  }

  Future<void> takePicture(BuildContext context, String path) async {
    if (_controller.value.isInitialized) {
      //final path = join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await _controller.takePicture();
      //Navigate to the PictureScreen with the path
      // MaterialPageRoute route = MaterialPageRoute(
      //   builder: (context) => PictureScreen(path, place),
      // );
      // Navigator.push(context, route);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

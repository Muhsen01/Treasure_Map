import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:treasure_map/place_dialog.dart';
import 'dbhelper.dart';
import 'manage_places.dart';
import 'place.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainMap(),
    );
  }
}

class MainMap extends StatefulWidget {
  @override
  _MainMapState createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  List<Marker> _markers = [];
  GoogleMapController? _mapController;
  late DbHelper helper;

  final CameraPosition position = CameraPosition(
    //target: LatLng(34.503363, -93.047302), //Hot Springs
    target: LatLng(41.902782, 12.496365), //Rome, Italy
    //target: LatLng(34.722386, -92.999224), //Home
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('The Treasure Map'),
        actions: <Widget>[
          IconButton(  //Hamburger ICON on AppBar
            icon: Icon(Icons.list),
            onPressed: () {
              MaterialPageRoute route =
                  MaterialPageRoute(builder: (context) => ManagePlaces());
              Navigator.push(context, route);
            },
          ),
        ],
      ),


      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_location),
        onPressed: () {
          int here = _markers.indexWhere((p)=> p.markerId == MarkerId('currpos'));
          Place place;
          if (here == -1) {
            //the current position is not available
            place = Place(0, '', 0, 0, '');
          }
          else {
            LatLng pos = _markers[here].position;
            place = Place(0, '', pos.latitude, pos.longitude, '');
          }

          PlaceDialog dialog = PlaceDialog(place, true); //open add place page
          showDialog(
              context: context,
              builder: (context) =>
                  dialog.buildAlert(context));
        },
      ),

      body: Container(
        child: GoogleMap(
          initialCameraPosition: position,
          markers: Set<Marker>.of(_markers),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    helper = DbHelper();
    helper.openDb().then((db) {
      //helper.insertMockData();
      _getData();
    }).catchError((error) {
    });

    _getCurrentLocation().then((pos) {
      _addMarker(pos, 'currpos', 'You are here!');
    }).catchError((err) => print(err.toString()));

    super.initState();
  }

  Future _getCurrentLocation() async {
    bool isGeolocationAvailable = await Geolocator.isLocationServiceEnabled();
    Position _position = Position(
      latitude: this.position.target.latitude,
      longitude: this.position.target.longitude,
      altitude: 0.0,
      speed: 0.0,
      accuracy: 0.0,
      heading: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      timestamp: DateTime(0),
      headingAccuracy: 0.0,
    );

    if (isGeolocationAvailable) {
      //if location service is available
      //get permission, if denied, request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    }

    // Check if permission is granted before getting the current position
    if (await Geolocator.checkPermission() == LocationPermission.always ||
        await Geolocator.checkPermission() == LocationPermission.whileInUse) {
      try {
        _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (error) {
        //if error, return default position, defined above

        return _position;
      }
    }
    return _position; //return acquired position or default position
  }

  void _addMarker(Position pos, String markerId, String markerTitle) {
    final marker = Marker(
        markerId: MarkerId(markerId),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: InfoWindow(title: markerTitle),
        icon: (markerId == 'currpos')
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange));
    _markers.add(marker);
    setState(() {});

    // move camera view to current postion
    if (_mapController != null && _markers.length != 0) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(
          _markers[0].position.latitude, _markers[0].position.longitude)));
    }
  }

  Future _getData() async {
    await helper.openDb();
    List<Place> _places = await helper.getPlaces();
    for (Place p in _places) {
      _addMarker(
          Position(
              latitude: p.lat,
              longitude: p.lon,
              altitude: 0.0,
              speed: 0.0,
              accuracy: 0.0,
              heading: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              timestamp: DateTime(0),
              headingAccuracy: 0.0),
          p.id.toString(),
          p.name);
    }
    setState(() {
      //_markers = _markers;
    });
  }
}

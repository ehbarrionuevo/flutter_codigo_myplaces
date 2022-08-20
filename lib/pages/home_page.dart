import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myplaces/utils/map_style.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _positions = [];
  Position? lastPosition;
  late GoogleMapController googleMapController;

  @override
  initState() {
    super.initState();
    currentPosition();
  }

  Future<CameraPosition> initCurrentPosition() async {
    Position currentPosition = await Geolocator.getCurrentPosition();
    return CameraPosition(
      zoom: 15,
      target: LatLng(currentPosition.latitude, currentPosition.longitude),
    );
  }

  Future<void> moveCamera() async {
    Position currentPosition = await Geolocator.getCurrentPosition();
    CameraUpdate cameraUpdate = CameraUpdate.newLatLng(
        LatLng(currentPosition.latitude, currentPosition.longitude));
    googleMapController.animateCamera(cameraUpdate);
  }

  Future<Uint8List> imageToBytes(String path,
      {bool fromNetwork = false, int width = 100}) async {
    late Uint8List bytes;

    if (fromNetwork) {
      File file = await DefaultCacheManager().getSingleFile(path);
      bytes = await file.readAsBytes();
    } else {
      ByteData byteData = await rootBundle.load(path);
      bytes = byteData.buffer.asUint8List();
    }

    final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
    ui.FrameInfo frame = await codec.getNextFrame();

    ByteData? myByteData =
    await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return myByteData!.buffer.asUint8List();
  }

  currentPosition() async {
    BitmapDescriptor positionIcon = BitmapDescriptor.fromBytes(
      await imageToBytes(
          "https://freesvg.org/img/car_topview.png",
          fromNetwork: true,
          width: 120
      ),
    );

    Polyline myPolyline = Polyline(
      polylineId: PolylineId("my_route"),
      points: _positions,
      color: Colors.pinkAccent,
      width: 7,
    );

    _polylines.add(myPolyline);

    Geolocator.getPositionStream().listen((Position event) {
      LatLng latLng = LatLng(event.latitude, event.longitude);
      _positions.add(latLng);

      CameraUpdate cameraUpdate = CameraUpdate.newLatLng(latLng);
      googleMapController.animateCamera(cameraUpdate);


      double rotation = 0;
      if(lastPosition != null){
        rotation =  Geolocator.bearingBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          latLng.latitude,
          latLng.longitude,
        );
      }

      Marker positionMarker = Marker(
          markerId: MarkerId('positionMarker'),
          position: latLng,
          icon: positionIcon,
          rotation: rotation
      );

      _markers.add(positionMarker);
      lastPosition = event;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: initCurrentPosition(),
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.hasData) {
            CameraPosition cameraPosition = snap.data;
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: cameraPosition,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  // mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    googleMapController = controller;
                    googleMapController.setMapStyle(jsonEncode(mapStyle));
                  },
                  onTap: (LatLng position) async {
                    MarkerId myMarkerId = MarkerId(_markers.length.toString());
                    Marker myMarker = Marker(
                        markerId: myMarkerId,
                        position: position,
                        // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        // icon: await BitmapDescriptor.fromAssetImage(
                        //   ImageConfiguration(),
                        //   'assets/images/marker2.png',
                        // ),
                        icon: BitmapDescriptor.fromBytes(await imageToBytes(
                            "https://pngimg.com/uploads/police_badge/police_badge_PNG97.png",
                            fromNetwork: true)),
                        rotation: 0,
                        draggable: true,
                        onDrag: (LatLng newPosition) {
                          print(newPosition);
                        },
                        onTap: () {
                          print("Holaaa");
                        });
                    _markers.add(myMarker);
                    setState(() {});
                  },
                  markers: _markers,
                  polylines: _polylines,

                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 20.0),
                    height: 48.0,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        moveCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.indigo,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0)),
                      ),
                      child: const Text(
                        "Mi ubicación",
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

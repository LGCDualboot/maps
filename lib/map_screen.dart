import 'dart:async';
import 'dart:math';

import 'package:custom_marker/marker_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golf_map/label_marker_custom.dart';
import 'package:golf_map/maps_cubit/maps_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      target: LatLng(37.43296265331129, -122.08832357078792),
      zoom: 19.151926040649414);

  final List<Marker> _markers = <Marker>[];
  final List<Marker> _middlePoints = <Marker>[];
  final List<Marker> _allMarkers = <Marker>[];

  final List<Marker> _otherMarkers = <Marker>[];

  final List<LatLng> _polylinePoints = <LatLng>[];

  final Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: GoogleMap(
      mapType: MapType.terrain,
      initialCameraPosition: _kGooglePlex,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      polylines: Set.of(_polylines.values),
      markers: Set.of(_allMarkers),

      onLongPress: (latlng) {
        print("SET OTHER MARKER");
        //_setOtherMarker(latlng);
        _setCustomMarker(latlng);
      },
      onTap: (latLng) {
        print("SET MARKER");
        _setMarker(latLng);
      },
    ));
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }

  void _calculatePolylineWithMultipleMarkersAndDistance() {
    final String polylineIdVal = uuid.v4();
    final PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.orange,
      width: 2,
      points: _polylinePoints,
    );

    _polylines.clear();
    _polylines[polylineId] = polyline;
  }

  void _setMarker(LatLng latLng) async {
    final markerId = MarkerId(uuid.v4());
    final Marker marker = Marker(
      markerId: markerId,
      position: latLng,
      draggable: true,
      onDrag: (latLng) async {
        print("DRAG");

        //_updatePoints(latLng);
        _updateMarkerPosition(markerId,latLng);

        await _calculateAllMiddlePoints();

        _setPolylinesPoints(_markers);

        _generateAllMarkers();

        _calculatePolylineWithMultipleMarkersAndDistance();


        setState(() {

        });
      }
    );

    if (_markers.length >= 2) {
      _markers.insert(_markers.length - 1, marker);
    } else {
      _markers.add(marker);
    }

    await _calculateAllMiddlePoints();

    _setPolylinesPoints(_markers);

    _generateAllMarkers();

    _calculatePolylineWithMultipleMarkersAndDistance();

    setState(() {});
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  void _updatePoints(LatLng latLng){
    _polylinePoints.removeWhere((point) => point.latitude != latLng.latitude);
    _polylinePoints.add(latLng);
  }

  void _updateMarkerPosition(MarkerId markerId,LatLng latLng){

    final indexOfMarker = _markers.indexWhere((m) => m.markerId == markerId);

    final oldMarker = _markers[indexOfMarker];
    _markers[indexOfMarker] = oldMarker.copyWith(positionParam: latLng);

  }

  int _calculateDistanceInMeters(LatLng firstPoint, LatLng secondPoint) {
    final latOrigin = firstPoint.latitude;
    final lngOrigin = firstPoint.longitude;
    final latDestination = secondPoint.latitude;
    final lngDestination = secondPoint.longitude;

    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((latDestination - latOrigin) * p) / 2 +
        cos(latOrigin * p) *
            cos(latDestination * p) *
            (1 - cos((lngDestination - lngOrigin) * p)) /
            2;

    final km = 12742 * asin(sqrt(a));
    final meters = (km * 1000).round();
    return meters;
  }

  LatLng _getPositionBetweenTwoPoints(LatLng firstPoint, LatLng secondPoint) {
    final x = (firstPoint.latitude + secondPoint.latitude) / 2;
    final y = (firstPoint.longitude + secondPoint.longitude) / 2;

    return LatLng(x, y);
  }

  Future<void> _calculateAllMiddlePoints() async {
    _middlePoints.clear();

    for (var i = 0; i < _markers.length - 1; i++) {
      final currentMarker = _markers[i];
      final nextMarker = _markers[i + 1];

      final distanceBetween = _calculateDistanceInMeters(
          currentMarker.position, nextMarker.position);

/*
      final middleMarker = Marker(markerId: MarkerId(uuid.v4()),position: _getPositionBetweenTwoPoints(
          currentMarker.position, nextMarker.position),);
*/

      final middleMarker = await customLabelMarker(LabelMarker(
        label: "${distanceBetween}m",
        markerId: MarkerId(uuid.v4()),
        position: _getPositionBetweenTwoPoints(
            currentMarker.position, nextMarker.position),
      ));

      _middlePoints.add(middleMarker);
    }
  }

  void _setOtherMarker(LatLng latLng) {
    setState(() {
      final Marker marker = Marker(
        markerId: MarkerId(uuid.v4()),
        position: latLng,
      );

      _otherMarkers.add(marker);

      _generateAllMarkers();
    });
  }

  void _setPolylinesPoints(List<Marker> markers) {
    _polylinePoints.clear();
    _polylinePoints.addAll(markers.map((m) => m.position));
  }

  Future<void> _generateAllMarkers() async {
    _allMarkers.clear();

    _allMarkers.addAll(_markers);
    _allMarkers.addAll(_middlePoints);
    _allMarkers.addAll(_otherMarkers);
  }

  void _setCustomMarker(LatLng latLng) async {
    final labelMarker = await customLabelMarker(LabelMarker(
        label: "EXAMPLE",
        markerId: MarkerId(uuid.v4()),
        position: latLng,
        onTap: () {
          print("CUSTOM MARKER");
        }));
    _otherMarkers.add(labelMarker);

    setState(() {
      _generateAllMarkers();
    });
  }
}

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:golf_map/main.dart';
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

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

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
        onLongPress: (latlng){
          print("SET OTHER MARKER");
          _setOtherMarker(latlng);
        },
        onTap: (latLng) {
          print("SET MARKER");
          _setMarker(latLng);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final marker1 = _markers.first;
          final marker2 = _markers.elementAt(1);
          _calculateDistanceInMeters(marker1.position, marker2.position);
          setState(() {

            final newMarker =
                _addMarkerBetweenTwoPoints(marker1.position, marker2.position);
            _markers.add(newMarker);

            _calculatePolylineWithMultipleMarkersAndDistance();
          });
        },
        child: Icon(Icons.directions_boat),
      ),
    );
  }

  LatLng _createLatLng(double lat, double lng) {
    return LatLng(lat, lng);
  }

  void _calculatePolylineWithTwoMarkers() {
    if (_markers.length == 2) {
      final String polylineIdVal = uuid.v4();
      final PolylineId polylineId = PolylineId(polylineIdVal);

      final Polyline polyline = Polyline(
        polylineId: polylineId,
        consumeTapEvents: true,
        color: Colors.orange,
        width: 5,
        points: [_markers.first.position, _markers.last.position],
      );

      _polylines[polylineId] = polyline;
    }
  }

  void _calculatePolylineWithMultipleMarkers() {
    final String polylineIdVal = uuid.v4();
    final PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.orange,
      geodesic: true,
      width: 2,
      points: _markers.map((marker) => marker.position).toList(),
    );

    _polylines[polylineId] = polyline;
  }

  void _calculatePolylineWithMultipleMarkersAndDistance() {
    final String polylineIdVal = uuid.v4();
    final PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.orange,
      width: 2,
      points: _markers.map((marker) => marker.position).toList(),
    );

    _polylines.clear();
    _polylines[polylineId] = polyline;
  }

  void _setMarker(LatLng latLng) async {
    setState(() {
      final Marker marker = Marker(
        markerId: MarkerId(uuid.v4()),
        position: latLng,
      );

      if (_markers.length >= 2) {
        _markers.insert(_markers.length - 1, marker);
      } else {
        _markers.add(marker);
      }

      _calculateAllMiddlePoints();

      _generateAllMarkers();

      _calculatePolylineWithMultipleMarkersAndDistance();

    });
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  void _calculateDistanceInMeters(LatLng firstPoint, LatLng secondPoint) async {
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
    print(meters);
  }

  Marker _addMarkerBetweenTwoPoints(LatLng firstPoint, LatLng secondPoint) {
    final x = (firstPoint.latitude + secondPoint.latitude) / 2;
    final y = (firstPoint.longitude + secondPoint.longitude) / 2;

    return Marker(
        markerId: MarkerId(uuid.v4()),
        position: LatLng(x, y),
        alpha: 0.5);
  }

  void _calculateAllMiddlePoints() {

    _middlePoints.clear();

    for (var i = 0; i < _markers.length - 1; i++) {
      final currentMarker = _markers[i];
      final nextMarker = _markers[i + 1];

      final middleMarker = _addMarkerBetweenTwoPoints(
          currentMarker.position, nextMarker.position);

      _middlePoints.add(middleMarker);
    }
  }

  void _setOtherMarker(LatLng latLng){
    setState(() {
      final Marker marker = Marker(
        markerId: MarkerId(uuid.v4()),
        position: latLng,
      );

      _otherMarkers.add(marker);

      _generateAllMarkers();

    });
  }

  void _generateAllMarkers(){

    _allMarkers.clear();

    _allMarkers.addAll(_markers);
    _allMarkers.addAll(_middlePoints);
    _allMarkers.addAll(_otherMarkers);

  }
}

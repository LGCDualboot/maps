import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:golf_map/label_marker_custom.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

part 'maps_state.dart';

const uuid = Uuid();

class MapsCubit extends Cubit<MapsState> {

  final Map<String,BitmapDescriptor> _cacheMiddlePoints = {};

  MapsCubit() : super(MapsState.empty());

  void setController(GoogleMapController controller) {
    emit(state.copyWith(controller: controller));
  }

  void setInitialCameraPosition(CameraPosition initialCameraPosition) {
    emit(state.copyWith(initialCameraPosition: initialCameraPosition));
  }

  // Calculate polylines with polylines point
  void calculatePolylines() {
    final String polylineIdVal = uuid.v4();
    final PolylineId polylineId = PolylineId(polylineIdVal);

    final Polyline polyline = Polyline(
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.orange,
      width: 2,
      points: state.polylinePoints,
    );

    emit(state.copyWith(polylines: {polylineId: polyline}));
  }

  void addMarker(Marker newMarker) {
    final markers = state.markers;
    markers.add(newMarker);
    emit(state.copyWith(markers: markers));
  }

  void addMarkerBeforeLastOne(Marker newMarker) {
    final markers = state.markers;
    markers.insert(markers.length - 1, newMarker);
    emit(state.copyWith(markers: markers));
  }

  void addMarkerAfterFirstOne(Marker newMarker) {
    final markers = state.markers;
    markers.insert(1, newMarker);
    emit(state.copyWith(markers: markers));
  }

  void setPolylinePoints(List<LatLng> points) {
    emit(state.copyWith(polylinePoints: points));
  }

  Future<void> calculateAllMiddlePointsBetweenMarkers() async {
    emit(state.copyWith(middlePoints: []));

    final markers = state.markers;
    final middlePoints = <Marker>[];

    for (var i = 0; i < markers.length - 1; i++) {
      final currentMarker = markers[i];
      final nextMarker = markers[i + 1];

      final distanceBetween = calculateDistanceInMeters(
          currentMarker.position, nextMarker.position);

      BitmapDescriptor? icon = _cacheMiddlePoints["${distanceBetween}m"];

      if(icon == null){
        icon = await createCustomMarkerBitmap(
            "${distanceBetween}m"
        );

        _cacheMiddlePoints["${distanceBetween}m"] = icon;
      }

      final middleMarker = Marker(
        markerId: MarkerId("${distanceBetween}m"),
        position: getPositionBetweenTwoPoints(
            currentMarker.position, nextMarker.position),
        icon: icon
      );

      middlePoints.add(middleMarker);
    }

    emit(state.copyWith(middlePoints: middlePoints));
  }

  LatLng getPositionBetweenTwoPoints(LatLng firstPoint, LatLng secondPoint) {
    final x = (firstPoint.latitude + secondPoint.latitude) / 2;
    final y = (firstPoint.longitude + secondPoint.longitude) / 2;

    return LatLng(x, y);
  }

  int calculateDistanceInMeters(LatLng firstPoint, LatLng secondPoint) {
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

  void setOtherMarker(Marker marker) {
    emit(state.copyWith(otherMarkers: state.otherMarkers..add(marker)));
  }


  void generateAllMarkers(){

    final allMarkers = <Marker>[
      ...state.markers,
      ...state.middlePoints,
      ...state.otherMarkers
    ];

    emit(state.copyWith(allMarkers: allMarkers));
  }

  void updateMarkerPosition(MarkerId markerId,LatLng latLng){

    final indexOfMarker = state.markers.indexWhere((m) => m.markerId == markerId);

    final oldMarker = state.markers[indexOfMarker];
    final markers = state.markers;
    markers[indexOfMarker] = oldMarker.copyWith(positionParam: latLng);
    emit(state.copyWith(markers: markers));

  }

  void drawMap(){
    if(state.controller == null){
      throw Exception("GoogleMapController is required to draw the map");
    }

    if(state.initialCameraPosition == null){
      throw Exception("InitialCameraPosition is required to draw the map");
    }

    emit(state.copyWith(idToDraw: uuid.v4()));
  }

  Future<void> setCacheOfMiddlePointsLabels(LatLng point1, LatLng point2) async {
    final meters = calculateDistanceInMeters(point1, point2);

    for (var i = 0; i < meters; i++) {
      _cacheMiddlePoints["${i}m"] = await createCustomMarkerBitmap(
        "${i}m"
      );
    }

  }
}

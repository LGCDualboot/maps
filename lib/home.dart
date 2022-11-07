import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golf_map/map_screen_with_cubit.dart';
import 'package:golf_map/maps_cubit/maps_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:ffi';
import 'dart:typed_data';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) {
              return BlocProvider(
                create: (BuildContext context) {
                  final cubit = MapsCubit();

                  var lat1 = 33.48218513403903;
                  var lng1 = -117.72088516319099;

                  var lat2 = 33.48028594020149;
                  var lng2 = -117.71801646379252;

                  var dLon = lng2 - lng1;
                  var y = sin(dLon) * cos(lat2);
                  var x =
                      cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
                  var brng = (atan2(y, x)) * 180 / pi;

                  brng = (360 - ((brng + 360) % 360));

                  CameraPosition initialCameraPosition = CameraPosition(
                    target: LatLng((lat1 + lat2) / 2, (lng1 + lng2) / 2),
                    zoom: 17.2,
                    bearing: brng,
                  );

                  final Marker marker1 = Marker(
                      markerId: MarkerId("1"), position: LatLng(lat1, lng1));
                  final Marker marker2 = Marker(
                      markerId: MarkerId("2"), position: LatLng(lat2, lng2));

                  cubit.setInitialCameraPosition(initialCameraPosition);
                  cubit.addMarker(marker1);
                  cubit.addMarker(marker2);

                  cubit.setCacheOfMiddlePointsLabels(marker1.position, marker2.position);


                  final middleMarker = Marker(
                      markerId: MarkerId("middleMarker"),
                      position: cubit.getPositionBetweenTwoPoints(
                          marker1.position, marker2.position),
                  draggable: true,
                    onDrag: (latLng) {
                        cubit.updateMarkerPosition(MarkerId("middleMarker"), latLng);

                        cubit.setPolylinePoints(cubit.state.markers.map((m) => m.position).toList());
                        cubit.calculatePolylines();

                        cubit.calculateAllMiddlePointsBetweenMarkers().then((value){
                          cubit.generateAllMarkers();
                          cubit.drawMap();
                        });

                    }
                  );

                  cubit.addMarkerBeforeLastOne(middleMarker);

                  cubit.setPolylinePoints(cubit.state.markers.map((m) => m.position).toList());

                  cubit.calculatePolylines();

                  cubit.generateAllMarkers();


                  return cubit;
                },
                child: MapScreenWithCubit(),
              );
            }));
          },
          child: Text("Go To map"),
        ),
      ),
    );
  }
}

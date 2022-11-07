import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golf_map/maps_cubit/maps_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreenWithCubit extends StatelessWidget {
  const MapScreenWithCubit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final cubit = context.read<MapsCubit>();
    final state = cubit.state;
    context.select((MapsCubit cubit) => cubit.state.idToDraw);

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: state.initialCameraPosition!,
        onMapCreated: (GoogleMapController controller){
          cubit.setController(controller);

          cubit.calculateAllMiddlePointsBetweenMarkers().then((value) {
            cubit.generateAllMarkers();
            cubit.drawMap();

          });
        },
        mapType: state.mapType,
        polylines: Set.of(state.polylines.values),
        markers: Set.of(state.allMarkers),
        polygons: Set.of(state.polygons),
        circles: Set.of(state.circles),
      ),
    );
  }
}

part of 'maps_cubit.dart';

class MapsState extends Equatable {
  final List<Marker> markers;
  final List<Marker> middlePoints;

  final List<Marker> allMarkers;
  final List<Marker> otherMarkers;

  final List<LatLng> polylinePoints;
  final Map<PolylineId, Polyline> polylines;

  final List<Circle> circles;
  final List<Polygon> polygons;

  final CameraPosition? initialCameraPosition;
  final GoogleMapController? controller;

  final MapType mapType;

  final String idToDraw;

  @override
  List<Object?> get props => [
        markers,
        middlePoints,
        allMarkers,
        otherMarkers,
        polylinePoints,
        polylines,
        circles,
        polygons,
        initialCameraPosition,
        controller,
        mapType,
    idToDraw
      ];

  MapsState({
    required this.markers,
    required this.middlePoints,
    required this.allMarkers,
    required this.otherMarkers,
    required this.polylinePoints,
    required this.polylines,
    required this.circles,
    required this.polygons,
    required this.mapType,
    this.initialCameraPosition,
    this.controller,
    this.idToDraw = ""
  });

  MapsState copyWith(
      {List<Marker>? markers,
      List<Marker>? middlePoints,
      List<Marker>? allMarkers,
      List<Marker>? otherMarkers,
      List<LatLng>? polylinePoints,
      Map<PolylineId, Polyline>? polylines,
      List<Circle>? circles,
      List<Polygon>? polygons,
      CameraPosition? initialCameraPosition,
      GoogleMapController? controller,
      MapType? mapType,
      String? idToDraw
      }) {
    return MapsState(
        allMarkers: allMarkers ?? this.allMarkers,
        middlePoints: middlePoints ?? this.middlePoints,
        polylines: polylines ?? this.polylines,
        mapType: mapType ?? this.mapType,
        markers: markers ?? this.markers,
        polylinePoints: polylinePoints ?? this.polylinePoints,
        circles: circles ?? this.circles,
        otherMarkers: otherMarkers ?? this.otherMarkers,
        polygons: polygons ?? this.polygons,
    idToDraw: idToDraw ?? this.idToDraw,
      initialCameraPosition: initialCameraPosition ?? this.initialCameraPosition,
      controller: controller ?? this.controller
    );
  }

  factory MapsState.empty() {
    return MapsState(
        circles: [],
        polylines: {},
        otherMarkers: [],
        polygons: [],
        middlePoints: [],
        allMarkers: [],
        mapType: MapType.terrain,
        markers: [],
        polylinePoints: [],
    idToDraw: ""
    );
  }
}

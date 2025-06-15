import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({
    super.key,
    required MapController mapController,
    required LatLng? currentLocation,
    required LatLng? destination,
    required List<LatLng> route,
    this.onTap,
  }) : _mapController = mapController, _currentLocation = currentLocation, _destination = destination, _route = route;

  final MapController _mapController;
  final LatLng? _currentLocation;
  final LatLng? _destination;
  final List<LatLng> _route;
  final Function(LatLng)? onTap;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? LatLng(30.0444, 31.2357),
        initialZoom: 15,
        minZoom: 0,
        maxZoom: 100,
        onTap: (_, latLng) {
          onTap?.call(latLng);
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        CurrentLocationLayer(
          style: const LocationMarkerStyle(
            marker: DefaultLocationMarker(
              child: Icon(Icons.location_pin, color: Colors.red),
            ),
            markerSize: Size(35, 35),
            markerDirection: MarkerDirection.heading,
          ),
        ),
        if (_destination != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _destination,
                width: 50,
                height: 50,
                child: Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        if (_currentLocation != null &&
            _destination != null &&
            _route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route,
                strokeWidth: 5,
                color: Colors.red,
              ),
            ],
          ),
      ],
    );
  }
}
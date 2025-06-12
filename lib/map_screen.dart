import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  final TextEditingController _locationController = TextEditingController();
  bool isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        title: const Text("Map", style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _userCurrentLocation,
        elevation: 0,
        child: Icon(Icons.my_location, size: 30),
      ),
      body: Stack(
        children: [
          isLoading ? Center(child: CircularProgressIndicator(),)
          : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? LatLng(30.0444, 31.2357),
                  initialZoom: 15,
                  minZoom: 0,
                  maxZoom: 100,
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
                          point: _destination!,
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
              ),
          Positioned(
            top: 10,
            right: 0,
            left: 0,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Enter a location",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      final location = _locationController.text.trim();
                      if (location.isNotEmpty) {
                        fetchCoordinatesPoint(location);
                      }
                    },
                    icon: Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeLocation() async {
    if (!await _checkTheRequestPermission()) return;

    _location.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          isLoading = false;
        });
        print("Current location: $_currentLocation");
      }
    });
  }

  Future<void> fetchCoordinatesPoint(String location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          _destination = LatLng(lat, lon);
        });
        await fetchRoute();
      } else {
        errorMessage("Location not found. Please try another location.");
      }
    } else {
      errorMessage("Failed to fetch location, Try again later.");
    }
  }

  Future<void> fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;
    final url = Uri.parse(
      "http://router.project-osrm.org/route/v1/driving/"
      '${_currentLocation!.longitude},${_currentLocation!.latitude};'
      '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      _decodePolyline(geometry);
    } else {
      errorMessage('Failed to fetch route..Try again later.');
    }
  }

  void _decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
      encodedPolyline,
    );

    setState(() {
      _route =
          decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
    });
  }

  Future<bool> _checkTheRequestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _userCurrentLocation() async {
    _initializeLocation();
    if (_currentLocation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$_currentLocation")));
      _mapController.move(_currentLocation!, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location is not available")),
      );
    }
  }

  void errorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, zoom + 1);
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, zoom - 1);
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orbitmap/src/data/model/marker_data.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<MarkerData> _markerData = [];
  final List<Marker> _markers = [];
  LatLng? _selectedPosition;
  LatLng? _mylocation;
  LatLng? _draggedPosition;
  bool _isDragging = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false; // Уберите final здесь

  // Определение функции для получения текущей позиции
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Службы определения местоположения отключены.");
      return Future.error("Службы определения местоположения отключены.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Права на определение местоположения отклонены.");
        return Future.error("Права на определение местоположения отклонены.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Права на определение местоположения навсегда отклонены.");
      return Future.error(
          "Права на определение местоположения навсегда отклонены.");
    }

    return await Geolocator.getCurrentPosition();
  }

  void _showCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      LatLng currentLatLng = LatLng(
        position.latitude,
        position.longitude,
      );
      _mapController.move(currentLatLng, 15.0);
      setState(() {
        _mylocation = currentLatLng;
      });
      print("Текущее местоположение: $currentLatLng");
    } catch (e) {
      print("Ошибка при получении текущего местоположения: $e");
    }
  }

  void _addMarker(LatLng position, String title, String description) {
    setState(() {
      final markerData = MarkerData(
          position: position, title: title, description: description);
      _markerData.add(markerData);
      _markers.add(
        Marker(
          point: position,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showMarkerInfo(markerData),
           
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showMarkerDialog(BuildContext context, LatLng position) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Добавить маркер"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Название"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Описание"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              _addMarker(
                position,
                titleController.text,
                descController.text,
              );
              Navigator.pop(context); 
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  void _showMarkerInfo(MarkerData markerData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(markerData.title),
        content: Text(markerData.description),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
    final response = await http.get(
      Uri.parse(url),
    );
    final data = json.decode(response.body);
    if (data.isNotEmpty) {
      setState(() {
        _searchResults = data;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _moveToLocation(double lat, double lon) {
    LatLng location = LatLng(lat, lon);
    _mapController.move(location, 15.0);
    setState(() {
      _selectedPosition = location;
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchPlaces(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(51.5, -0.09),
              initialZoom: 13.0,
              onTap: (tapPosition, latLng) {
               setState(() {
                  _selectedPosition = latLng;
                _draggedPosition = _selectedPosition;
                
               });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(markers: _markers),
              if (_isDragging && _draggedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _draggedPosition!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.indigo,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_mylocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _mylocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Column(
              children: [
                SizedBox(
                  height: 55,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Искать место...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _searchResults = [];
                                });
                              },
                              icon: Icon(Icons.clear),
                            )
                          : null,
                    ),
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                ),
                if (_isSearching && _searchResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          title: Text(place['display_name']),
                          onTap: () {
                            final lat = double.parse(place['lat']);
                            final lon = double.parse(place['lon']);
                            _moveToLocation(lat, lon);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          _isDragging == false
              ? Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isDragging = true;
                      });
                    },
                    child: Icon(Icons.add_location),
                  ),
                )
              : Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isDragging = false;
                      });
                    },
                    child: Icon(Icons.wrong_location),
                  ),
                ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  onPressed: _showCurrentLocation,
                  child: Icon(Icons.location_searching_rounded),
                ),
                if (_isDragging)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: FloatingActionButton(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        if (_draggedPosition != null) {
                          _showMarkerDialog(context, _draggedPosition!);
                        }
                        setState(() {
                          _isDragging = false;
                          _draggedPosition = null;
                        });
                      },
                      child: Icon(Icons.check),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

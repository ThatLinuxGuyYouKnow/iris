import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iris/services/geolocation_service.dart';
import 'package:iris/services/route_store.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/campus_node.dart';
import 'package:iris/services/routing/hazard.dart';
import 'package:iris/services/routing/routing_engine.dart';
import 'package:iris/services/routing/sample_campus.dart';
import 'package:iris/services/tts_service.dart';
import 'package:iris/themes/theme.dart';
import 'package:latlong2/latlong.dart';

class RouteScreen extends StatefulWidget {
  final String? startNodeId;
  final String? endNodeId;

  const RouteScreen({super.key, this.startNodeId, this.endNodeId});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late final CampusGraph _graph;
  late final RoutingEngine _engine;
  final MapController _mapController = MapController();
  final TextToSpeechService _tts = TextToSpeechService();
  final GeolocationService _geo = GeolocationService();

  List<CampusNode> _nodes = const [];
  List<Hazard> _hazards = const [];
  String? _startId;
  String? _endId;
  RouteResult _route = const RouteResult(
    waypoints: [],
    polyline: [],
    cost: 0,
    distanceMetres: 0,
    encounteredHazards: [],
  );
  bool _loading = true;

  // Live GPS state. The user-position dot + accuracy halo draw on top of the
  // route so the user can see where they are relative to the planned path.
  GeoPosition? _userPosition;
  StreamSubscription<GeoPosition>? _positionSub;
  String? _gpsStatus;

  @override
  void initState() {
    super.initState();
    _graph = loadCampusGraph();
    _engine = RoutingEngine(_graph);
    _nodes = _graph.nodeList;
    _start();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    await RouteStore.instance.init();
    _hazards = await RouteStore.instance.listHazards();

    if (widget.endNodeId != null && _graph.node(widget.endNodeId!) != null) {
      _endId = widget.endNodeId;
    }

    if (widget.startNodeId != null && _graph.node(widget.startNodeId!) != null) {
      _startId = widget.startNodeId;
    } else {
      try {
        final fix = await _geo.getPosition(highAccuracy: true);
        final nearest = _graph.nearestNode(
          LatLng(fix.latitude, fix.longitude),
        );
        _startId = nearest.id;
      } catch (_) {
        _startId = _nodes.isNotEmpty ? _nodes.first.id : null;
      }
    }

    if (_startId != null && _endId != null) {
      _recompute();
    } else if (_nodes.length >= 2) {
      _startId ??= _nodes.first.id;
      _endId ??= _nodes[3].id;
      _recompute();
    }
    _startLocationWatch();
    if (mounted) setState(() => _loading = false);
  }

  void _startLocationWatch() {
    if (!_geo.isSupported) {
      _gpsStatus = 'Location not supported in this browser.';
      return;
    }
    _positionSub = _geo
        .watchPosition(highAccuracy: true)
        .listen(
          (pos) {
            if (!mounted) return;
            setState(() {
              _userPosition = pos;
              _gpsStatus = null;
            });
          },
          onError: (Object e) {
            if (!mounted) return;
            final msg = e is GeolocationException ? e.humanDescription : '$e';
            setState(() => _gpsStatus = msg);
          },
        );
  }

  void _recenterOnMe() {
    final pos = _userPosition;
    if (pos == null) return;
    _mapController.move(LatLng(pos.latitude, pos.longitude), 18);
  }

  void _recompute() {
    if (_startId == null || _endId == null) return;
    final result = _engine.routeBetween(
      _startId!,
      _endId!,
      activeHazards: _hazards,
    );
    setState(() => _route = result);
    if (result.polyline.length >= 2) {
      // Fit the map to the computed path once the map has rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: result.polyline,
            padding: const EdgeInsets.all(60),
          ),
        );
      });
    }
  }

  String _describe(RouteResult r) {
    if (r.isEmpty) return 'No route found — try different endpoints.';
    final km = (r.distanceMetres / 1000).toStringAsFixed(2);
    final turns = r.waypoints.length - 1;
    final buffer = StringBuffer()
      ..write(
        'Route from ${r.waypoints.first.label} to '
        '${r.waypoints.last.label}. ',
      )
      ..write('About $km kilometres, $turns turns. ');
    if (r.encounteredHazards.isEmpty) {
      buffer.write('No reported hazards on this path.');
    } else {
      buffer.write('Heads up: ');
      buffer.write(r.encounteredHazards.map((h) => h.type.label).join(', '));
      buffer.write(' reported along the way.');
    }
    return buffer.toString();
  }

  Future<void> _speakRoute() async {
    final desc = _describe(_route);
    if (desc.isNotEmpty) {
      if (_route.encounteredHazards.isNotEmpty) {
        _tts.playAudio('heads_up_obstacle_closeby.mp3');
      }
      _tts.speak(desc);
    }
  }

  Future<void> _saveRoute() async {
    if (_route.isEmpty) return;
    final name = await _promptForName();
    if (name == null || name.trim().isEmpty) return;
    await RouteStore.instance.saveRoute(name.trim(), _route.polyline);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved route "$name"')));
  }

  Future<String?> _promptForName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save route'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Route name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Route')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = (constraints.maxHeight * 0.52).clamp(280.0, 520.0);

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  _selectors(),
                  SizedBox(
                    height: mapHeight,
                    child: Stack(
                      children: [
                        _map(),
                        if (_gpsStatus != null)
                          Positioned(
                            top: 8,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orangeAccent),
                              ),
                              child: Text(
                                _gpsStatus!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _summaryPanel(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _userPosition == null ? null : _recenterOnMe,
        backgroundColor: kPrimaryAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _selectors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: _nodeDropdown('From', _startId, (v) {
              _startId = v;
              _recompute();
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _nodeDropdown('To', _endId, (v) {
              _endId = v;
              _recompute();
            }),
          ),
        ],
      ),
    );
  }

  Widget _nodeDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: kGlassDecoration(
        opacity: 0.05,
        borderRadius: 12,
      ).copyWith(border: Border.all(color: kDivider)),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          for (final n in _nodes)
            DropdownMenuItem(value: n.id, child: Text(n.label)),
        ],
        onChanged: onChanged,
        hint: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  Widget _map() {
    final user = _userPosition;
    final userLatLng = user == null
        ? null
        : LatLng(user.latitude, user.longitude);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _graph.nodeList.first.position,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.iris',
        ),
        // Accuracy halo: a geographically-sized circle whose radius in metres
        // equals the reported GPS accuracy, so the user can see how uncertain
        // the fix is. Rendered beneath the route polyline and markers.
        if (userLatLng != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: userLatLng,
                color: kPrimaryAccent.withValues(alpha: 0.18),
                radius: user!.accuracyMetres,
                useRadiusInMeter: true,
                borderColor: kPrimaryAccent.withValues(alpha: 0.5),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        if (_route.polyline.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route.polyline,
                color: kPrimaryAccent,
                strokeWidth: 6,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_route.waypoints.isNotEmpty)
              _marker(_route.waypoints.first.position, Colors.green, 'Start'),
            if (_route.waypoints.length >= 2)
              _marker(_route.waypoints.last.position, Colors.red, 'End'),
            for (final h in _hazards)
              _marker(h.position, Colors.orange, h.type.label),
          ],
        ),
        // User dot on its own layer so it draws above everything else.
        if (userLatLng != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLatLng,
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryAccent.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Marker _marker(LatLng point, Color color, String label) {
    return Marker(
      point: point,
      width: 30,
      height: 30,
      alignment: Alignment.topCenter,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _summaryPanel() {
    final km = (_route.distanceMetres / 1000).toStringAsFixed(2);
    final hasRoute = !_route.isEmpty;
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kDivider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRoute) ...[
              Text(
                '${_route.waypoints.first.label} → ${_route.waypoints.last.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$km km · ${_route.encounteredHazards.length} hazard(s) on path',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              Text(
                'Pick two different places to compute a route.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: hasRoute ? _speakRoute : null,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Speak route'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: hasRoute ? _saveRoute : null,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

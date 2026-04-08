import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// Full-screen map using [OpenStreetMap raster tiles](https://operations.osmfoundation.org/policies/tiles/)
/// (same data project as Nominatim reverse geocoding used elsewhere).
class LiveLocationOsmMapPage extends ConsumerStatefulWidget {
  const LiveLocationOsmMapPage({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.placeLabel,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String? placeLabel;

  @override
  ConsumerState<LiveLocationOsmMapPage> createState() =>
      _LiveLocationOsmMapPageState();
}

class _LiveLocationOsmMapPageState extends ConsumerState<LiveLocationOsmMapPage> {
  static const double _zoom = 16;

  late double _lat;
  late double _lng;
  late final LatLng _initialMapCenter;
  String? _label;
  bool _busy = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLatitude;
    _lng = widget.initialLongitude;
    _initialMapCenter = LatLng(_lat, _lng);
    _label = widget.placeLabel?.trim().isNotEmpty == true
        ? widget.placeLabel!.trim()
        : null;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshPosition() async {
    if (_busy) return;
    setState(() => _busy = true);
    final pos = await ref.read(locationServiceProvider).fetchHighAccuracyPosition();
    if (!mounted) return;
    setState(() => _busy = false);
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not refresh location. Check GPS and permissions.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(LatLng(_lat, _lng), _zoom);
      }
    });
    final coords =
        LocationService.formatCoordinatesForStorage(_lat, _lng);
    final pl = await LocationService.placeLabelFromCoordinateString(coords);
    if (mounted && pl.trim().isNotEmpty) {
      setState(() => _label = pl.trim());
    }
  }

  Future<void> _openOsmCopyright() async {
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppThemeColors.backgroundColor(context);
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final cs = Theme.of(context).colorScheme;
    final point = LatLng(_lat, _lng);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppThemeColors.appBarTitle(
        context,
        'Live location',
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _busy ? null : _refreshPosition,
            icon: _busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onSurface,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_label != null) ...[
                  Text(
                    _label!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // Keep stable so rebuilds (e.g. after refresh) do not reset pan/zoom.
                    initialCenter: _initialMapCenter,
                    initialZoom: _zoom,
                    minZoom: 3,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app.atl.crm',
                    ),
                    // Center-aligned icon: geographic point = icon center (avoids tip/padding drift when zooming).
                    MarkerLayer(
                      rotate: false,
                      markers: [
                        Marker(
                          point: point,
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          rotate: false,
                          child: Icon(
                            Icons.location_on,
                            size: 36,
                            color: cs.primary,
                            shadows: const [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black26,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          '© OpenStreetMap contributors',
                          onTap: () {
                            _openOsmCopyright();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

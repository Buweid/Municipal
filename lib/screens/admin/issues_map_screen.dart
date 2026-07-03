import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show PolygonLayer;
import 'package:latlong2/latlong.dart';

class IssuesMapScreen extends StatefulWidget {
  const IssuesMapScreen({super.key});

  @override
  State<IssuesMapScreen> createState() => _IssuesMapScreenState();
}

class _IssuesMapScreenState extends State<IssuesMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _issues = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'approved': Colors.blue,
    'in_progress': Colors.purple,
    'resolved': const Color(0xFF2E7D32),
    'rejected': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadIssues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('issues')
          .get();

      setState(() {
        _issues = snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((d) =>
        d['latitude'] != null && d['longitude'] != null)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredIssues {
    if (_selectedFilter == 'all') return _issues;
    return _issues
        .where((i) => (i['status'] ?? '') == _selectedFilter)
        .toList();
  }

  // ── ISSUE MARKER POPUP ───────────────────────────────────────────
  void _showIssuePopup(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final color = _statusColors[status] ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(data['userName'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
                const SizedBox(width: 16),
                const Icon(Icons.category_outlined,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(data['issueType'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
            if (data['imageUrl'] != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  data['imageUrl'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── HEAT MAP GRID ────────────────────────────────────────────────
  // We divide Muscat into a grid and count issues per cell
  List<Map<String, dynamic>> _buildHeatCells() {
    if (_issues.isEmpty) return [];

    const gridSize = 0.02; // ~2km cells
    Map<String, int> cellCount = {};
    Map<String, LatLng> cellCenter = {};

    for (final issue in _issues) {
      final lat = (issue['latitude'] as num).toDouble();
      final lng = (issue['longitude'] as num).toDouble();

      // Snap to grid
      final gridLat = (lat / gridSize).floor() * gridSize;
      final gridLng = (lng / gridSize).floor() * gridSize;
      final key = '$gridLat,$gridLng';

      cellCount[key] = (cellCount[key] ?? 0) + 1;
      cellCenter[key] = LatLng(
        gridLat + gridSize / 2,
        gridLng + gridSize / 2,
      );
    }

    final maxCount =
    cellCount.values.isEmpty ? 1 : cellCount.values.reduce((a, b) => a > b ? a : b);

    return cellCount.entries.map((e) {
      final intensity = e.value / maxCount;
      return {
        'center': cellCenter[e.key]!,
        'count': e.value,
        'intensity': intensity,
        'gridSize': gridSize,
      };
    }).toList();
  }

  Color _heatColor(double intensity) {
    if (intensity < 0.25) return Colors.green.withOpacity(0.4);
    if (intensity < 0.5) return Colors.yellow.withOpacity(0.5);
    if (intensity < 0.75) return Colors.orange.withOpacity(0.6);
    return Colors.red.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues Map'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.black45,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Issue Map'),
            Tab(icon: Icon(Icons.layers), text: 'Heat Map'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIssues,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: ISSUE MAP ─────────────────────
          Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in [
                        'all',
                        'pending',
                        'approved',
                        'in_progress',
                        'resolved',
                        'rejected',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter == 'all'
                                  ? 'All (${_issues.length})'
                                  : '${filter.replaceAll('_', ' ')} (${_issues.where((i) => i['status'] == filter).length})',
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _selectedFilter == filter,
                            onSelected: (_) => setState(
                                    () => _selectedFilter = filter),
                            selectedColor: const Color(0xFF2E7D32)
                                .withOpacity(0.15),
                            checkmarkColor: const Color(0xFF2E7D32),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Map
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(23.5880, 58.3829),
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                      'com.muscat.municipality',
                    ),
                    MarkerLayer(
                      markers: _filteredIssues.map((issue) {
                        final status =
                            issue['status'] ?? 'pending';
                        final color =
                            _statusColors[status] ?? Colors.grey;
                        return Marker(
                          point: LatLng(
                            (issue['latitude'] as num).toDouble(),
                            (issue['longitude'] as num).toDouble(),
                          ),
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => _showIssuePopup(issue),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    color.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.report_problem,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Legend
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _statusColors.entries.map((e) {
                    return Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: e.value,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          e.key.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          // ── TAB 2: HEAT MAP ──────────────────────
          Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(23.5880, 58.3829),
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                    'com.muscat.municipality',
                  ),
                  // Heat cells as colored circles
                  MarkerLayer(
                    markers: _buildHeatCells().map((cell) {
                      final center = cell['center'] as LatLng;
                      final intensity =
                      cell['intensity'] as double;
                      final count = cell['count'] as int;

                      return Marker(
                        point: center,
                        width: 60,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _heatColor(intensity),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Heat map legend
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issue Density',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _heatLegendRow(Colors.green, 'Low'),
                      const SizedBox(height: 4),
                      _heatLegendRow(Colors.yellow, 'Medium'),
                      const SizedBox(height: 4),
                      _heatLegendRow(Colors.orange, 'High'),
                      const SizedBox(height: 4),
                      _heatLegendRow(Colors.red, 'Critical'),
                    ],
                  ),
                ),
              ),

              // Issue count
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    '${_issues.length} total issues',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heatLegendRow(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
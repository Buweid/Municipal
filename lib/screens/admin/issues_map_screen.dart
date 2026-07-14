import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';

class IssuesMapScreen extends StatefulWidget {
  const IssuesMapScreen({super.key});

  @override
  State<IssuesMapScreen> createState() =>
      _IssuesMapScreenState();
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
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('issues')
          .get();

      if (!mounted) return;
      setState(() {
        _issues = snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((d) =>
        d['latitude'] != null &&
            d['longitude'] != null)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredIssues {
    if (_selectedFilter == 'all') return _issues;
    return _issues
        .where(
            (i) => (i['status'] ?? '') == _selectedFilter)
        .toList();
  }

  void _showIssuePopup(
      Map<String, dynamic> data, AppLocalizations l10n) {
    final status = data['status'] ?? 'pending';
    final color = _statusColors[status] ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                      AppTheme.textPrimaryColor(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withOpacity(0.5)),
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
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14,
                    color:
                    AppTheme.textSecondaryColor(context)),
                const SizedBox(width: 4),
                Text(
                  data['userName'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.category_outlined,
                    size: 14,
                    color:
                    AppTheme.textSecondaryColor(context)),
                const SizedBox(width: 4),
                Text(
                  data['issueType'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    AppTheme.textSecondaryColor(context),
                  ),
                ),
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildHeatCells() {
    if (_issues.isEmpty) return [];

    const gridSize = 0.02;
    Map<String, int> cellCount = {};
    Map<String, LatLng> cellCenter = {};

    for (final issue in _issues) {
      final lat = (issue['latitude'] as num).toDouble();
      final lng = (issue['longitude'] as num).toDouble();

      final gridLat = (lat / gridSize).floor() * gridSize;
      final gridLng = (lng / gridSize).floor() * gridSize;
      final key = '$gridLat,$gridLng';

      cellCount[key] = (cellCount[key] ?? 0) + 1;
      cellCenter[key] = LatLng(
        gridLat + gridSize / 2,
        gridLng + gridSize / 2,
      );
    }

    final maxCount = cellCount.values.isEmpty
        ? 1
        : cellCount.values
        .reduce((a, b) => a > b ? a : b);

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
    if (intensity < 0.25) {
      return Colors.green.withOpacity(0.4);
    }
    if (intensity < 0.5) {
      return Colors.yellow.withOpacity(0.5);
    }
    if (intensity < 0.75) {
      return Colors.orange.withOpacity(0.6);
    }
    return Colors.red.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.issuesMapTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor:
          AppTheme.textSecondaryColor(context),
          tabs: [
            Tab(
              icon: const Icon(Icons.map),
              text: l10n.issueMap,
            ),
            Tab(
              icon: const Icon(Icons.layers),
              text: l10n.heatMap,
            ),
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
                padding: const EdgeInsets.fromLTRB(
                    12, 8, 12, 4),
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
                          padding:
                          const EdgeInsets.only(
                              right: 8),
                          child: FilterChip(
                            label: Text(
                              filter == 'all'
                                  ? '${l10n.all} (${_issues.length})'
                                  : '${filter.replaceAll('_', ' ')} (${_issues.where((i) => i['status'] == filter).length})',
                              style: const TextStyle(
                                  fontSize: 11),
                            ),
                            selected:
                            _selectedFilter ==
                                filter,
                            onSelected: (_) =>
                                setState(() =>
                                _selectedFilter =
                                    filter),
                            selectedColor: AppTheme
                                .primary
                                .withOpacity(0.15),
                            checkmarkColor:
                            AppTheme.primary,
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
                    initialCenter:
                    LatLng(23.5880, 58.3829),
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
                      markers:
                      _filteredIssues.map((issue) {
                        final status =
                            issue['status'] ?? 'pending';
                        final color =
                            _statusColors[status] ??
                                Colors.grey;
                        return Marker(
                          point: LatLng(
                            (issue['latitude'] as num)
                                .toDouble(),
                            (issue['longitude'] as num)
                                .toDouble(),
                          ),
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => _showIssuePopup(
                                issue, l10n),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white,
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color
                                        .withOpacity(
                                        0.4),
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
                color: AppTheme.cardColor(context),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: _statusColors.entries
                      .map((e) {
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
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme
                                .textSecondaryColor(
                                context),
                          ),
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
                  initialCenter:
                  LatLng(23.5880, 58.3829),
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
                    markers:
                    _buildHeatCells().map((cell) {
                      final center =
                      cell['center'] as LatLng;
                      final intensity =
                      cell['intensity'] as double;
                      final count = cell['count'] as int;

                      return Marker(
                        point: center,
                        width: 60,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                            _heatColor(intensity),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                FontWeight.bold,
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
                    color: AppTheme.cardColor(context),
                    borderRadius:
                    BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                        AppTheme.shadowColor(context),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.issueDensity,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textPrimaryColor(
                              context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _heatLegendRow(
                          Colors.green, l10n.low),
                      const SizedBox(height: 4),
                      _heatLegendRow(
                          Colors.yellow, l10n.medium),
                      const SizedBox(height: 4),
                      _heatLegendRow(
                          Colors.orange, l10n.high),
                      const SizedBox(height: 4),
                      _heatLegendRow(
                          Colors.red, l10n.critical),
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
                    color: AppTheme.cardColor(context),
                    borderRadius:
                    BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                        AppTheme.shadowColor(context),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_issues.length} ${l10n.totalIssuesMap}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color:
                      AppTheme.textPrimaryColor(
                          context),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}
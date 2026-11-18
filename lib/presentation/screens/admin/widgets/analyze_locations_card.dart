import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../routes/app_routes.dart';
import '../../../../data/models/city_model.dart';
import '../../../../data/models/district_model.dart';
import '../../../../data/models/state_model.dart';
import '../../../../data/repositories/location_repository.dart';

/// Overview card with state, district, and city totals.
/// Tapping the card, or one of the counts, opens a searchable list.
class AnalyzeLocationsCard extends StatefulWidget {
  const AnalyzeLocationsCard({super.key});

  @override
  State<AnalyzeLocationsCard> createState() => _AnalyzeLocationsCardState();
}

class _AnalyzeLocationsCardState extends State<AnalyzeLocationsCard> {
  final LocationRepository _repo = LocationRepository();

  bool _loading = true;
  bool _statesLoaded = false;
  bool _districtsLoaded = false;
  bool _citiesLoaded = false;
  List<StateModel> _states = const [];
  List<DistrictModel> _districts = const [];
  List<CityModel> _cities = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      final stateFuture = _repo.getAllStates();
      final districtFuture = _repo.getAllDistricts();
      final cityFuture = _repo.getAllCities();
      final stateRes = await stateFuture;
      final districtRes = await districtFuture;
      final cityRes = await cityFuture;
      if (!mounted) return;

      final states = List<StateModel>.from(
        stateRes.success ? (stateRes.data ?? const <StateModel>[]) : const [],
      );
      final districts = List<DistrictModel>.from(
        districtRes.success
            ? (districtRes.data ?? const <DistrictModel>[])
            : const [],
      );
      final cities = List<CityModel>.from(
        cityRes.success ? (cityRes.data ?? const <CityModel>[]) : const [],
      );
      states.sort(
        (a, b) =>
            a.stateName.toLowerCase().compareTo(b.stateName.toLowerCase()),
      );
      districts.sort(
        (a, b) => a.districtName.toLowerCase().compareTo(
          b.districtName.toLowerCase(),
        ),
      );
      cities.sort(
        (a, b) => a.cityName.toLowerCase().compareTo(b.cityName.toLowerCase()),
      );

      setState(() {
        _states = states;
        _districts = districts;
        _cities = cities;
        _statesLoaded = stateRes.success;
        _districtsLoaded = districtRes.success;
        _citiesLoaded = cityRes.success;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _states = const [];
        _districts = const [];
        _cities = const [];
        _statesLoaded = false;
        _districtsLoaded = false;
        _citiesLoaded = false;
        _loading = false;
      });
    }
  }

  Future<void> _openList(int initialIndex) async {
    if (_loading) return;
    if (!_statesLoaded && !_districtsLoaded && !_citiesLoaded) {
      await _load();
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _AnalyzeLocationsDialog(
        states: _states,
        districts: _districts,
        cities: _cities,
        statesLoaded: _statesLoaded,
        districtsLoaded: _districtsLoaded,
        citiesLoaded: _citiesLoaded,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final color = AppTheme.primaryColor;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openList(0),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.08)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insights,
                        color: color,
                        size: isMobile ? 22 : 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Analyze Locations',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 13 : 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[500], size: 22),
                  ],
                ),
                const Spacer(),
                if (_loading)
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (!_statesLoaded && !_districtsLoaded && !_citiesLoaded)
                  Text(
                    'Could not load counts. Tap to retry.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Row(
                    children: [
                      _CountTap(
                        label: 'States',
                        value: _statesLoaded ? _states.length : null,
                        color: color,
                        isMobile: isMobile,
                        onTap: () => _openList(0),
                      ),
                      _countDivider(),
                      _CountTap(
                        label: 'Districts',
                        value: _districtsLoaded ? _districts.length : null,
                        color: color,
                        isMobile: isMobile,
                        onTap: () => _openList(1),
                      ),
                      _countDivider(),
                      _CountTap(
                        label: 'Cities',
                        value: _citiesLoaded ? _cities.length : null,
                        color: color,
                        isMobile: isMobile,
                        onTap: () => _openList(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _countDivider() {
  return Container(
    width: 1,
    height: 28,
    color: Colors.grey.shade200,
  );
}

String _formatCount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

String _sectionLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final letter = trimmed[0].toUpperCase();
  return RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
}

class _CountTap extends StatelessWidget {
  const _CountTap({
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
    required this.onTap,
  });

  final String label;
  final int? value;
  final Color color;
  final bool isMobile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value == null ? '—' : _formatCount(value!),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isMobile ? 18 : 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 11 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzeLocationsDialog extends StatefulWidget {
  const _AnalyzeLocationsDialog({
    required this.states,
    required this.districts,
    required this.cities,
    required this.statesLoaded,
    required this.districtsLoaded,
    required this.citiesLoaded,
    required this.initialIndex,
  });

  final List<StateModel> states;
  final List<DistrictModel> districts;
  final List<CityModel> cities;
  final bool statesLoaded;
  final bool districtsLoaded;
  final bool citiesLoaded;
  final int initialIndex;

  @override
  State<_AnalyzeLocationsDialog> createState() => _AnalyzeLocationsDialogState();
}

class _AnalyzeLocationsDialogState extends State<_AnalyzeLocationsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialIndex.clamp(0, 2);
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: _tabIndex,
    );
    _tabs.addListener(() {
      if (_tabs.indexIsChanging || _tabs.index == _tabIndex) return;
      setState(() => _tabIndex = _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<StateModel> get _filteredStates {
    if (_query.isEmpty) return widget.states;
    return widget.states
        .where(
          (s) =>
              s.stateName.toLowerCase().contains(_query) ||
              s.stateCode.toLowerCase().contains(_query),
        )
        .toList();
  }

  List<DistrictModel> get _filteredDistricts {
    if (_query.isEmpty) return widget.districts;
    return widget.districts
        .where(
          (d) =>
              d.districtName.toLowerCase().contains(_query) ||
              (d.stateName ?? '').toLowerCase().contains(_query),
        )
        .toList();
  }

  List<CityModel> get _filteredCities {
    if (_query.isEmpty) return widget.cities;
    return widget.cities
        .where(
          (c) =>
              c.cityName.toLowerCase().contains(_query) ||
              c.districtName.toLowerCase().contains(_query) ||
              c.stateName.toLowerCase().contains(_query) ||
              c.pincode.toLowerCase().contains(_query),
        )
        .toList();
  }

  void _openAddScreen() {
    const sections = ['state', 'district', 'city'];
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.settingsPath(tab: sections[_tabIndex]));
  }

  String _resultLine({
    required int shown,
    required int total,
    required String singular,
    required String plural,
  }) {
    final noun = shown == 1 ? singular : plural;
    if (_query.isEmpty || shown == total) {
      return '${_formatCount(shown)} $noun';
    }
    return '${_formatCount(shown)} of ${_formatCount(total)} $noun';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final color = AppTheme.primaryColor;
    final hints = const [
      'Search by state or code',
      'Search by district or state',
      'Search by city, district, or pincode',
    ];
    final resultLine = switch (_tabIndex) {
      1 => _resultLine(
        shown: _filteredDistricts.length,
        total: widget.districts.length,
        singular: 'district',
        plural: 'districts',
      ),
      2 => _resultLine(
        shown: _filteredCities.length,
        total: widget.cities.length,
        singular: 'city',
        plural: 'cities',
      ),
      _ => _resultLine(
        shown: _filteredStates.length,
        total: widget.states.length,
        singular: 'state',
        plural: 'states',
      ),
    };

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 28,
        vertical: isMobile ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile ? size.width : 760,
        height: size.height * (isMobile ? 0.88 : 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.insights, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analyze Locations',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse states, districts, and cities',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: const [
                      'Add state',
                      'Add district',
                      'Add city',
                    ][_tabIndex],
                    onPressed: _openAddScreen,
                    icon: Icon(Icons.add_circle, color: color, size: 28),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _LocationTabs(
                controller: _tabs,
                color: color,
                isMobile: isMobile,
                labels: [
                  'States · ${_formatCount(widget.states.length)}',
                  'Districts · ${_formatCount(widget.districts.length)}',
                  'Cities · ${_formatCount(widget.cities.length)}',
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                controller: _searchController,
                autofocus: !isMobile,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF6F7F6),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  hintText: hints[_tabIndex],
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 1.4),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Text(
                resultLine,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _StatePlaceList(
                    states: widget.states,
                    query: _query,
                    failed: !widget.statesLoaded,
                  ),
                  _DistrictPlaceList(
                    districts: widget.districts,
                    query: _query,
                    failed: !widget.districtsLoaded,
                  ),
                  _CityPlaceList(
                    cities: widget.cities,
                    query: _query,
                    failed: !widget.citiesLoaded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTabs extends StatelessWidget {
  const _LocationTabs({
    required this.controller,
    required this.color,
    required this.isMobile,
    required this.labels,
  });

  final TabController controller;
  final Color color;
  final bool isMobile;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F3),
        borderRadius: radius,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: color, borderRadius: radius),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[800],
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 12 : 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : 13,
        ),
        tabs: [
          for (final label in labels)
            Tab(
              height: isMobile ? 34 : 38,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceRow {
  const _PlaceRow({
    required this.title,
    this.subtitle = '',
    this.badge = '',
  });

  final String title;
  final String subtitle;
  final String badge;
}

class _StatePlaceList extends StatelessWidget {
  const _StatePlaceList({
    required this.states,
    required this.query,
    required this.failed,
  });

  final List<StateModel> states;
  final String query;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final rows = <_PlaceRow>[
      for (final state in states)
        if (query.isEmpty ||
            state.stateName.toLowerCase().contains(query) ||
            state.stateCode.toLowerCase().contains(query))
          _PlaceRow(title: state.stateName, badge: state.stateCode),
    ];
    return _PlaceList(
      rows: rows,
      searching: query.isNotEmpty,
      failed: failed,
      emptyLabel: 'No states found.',
      failedLabel: 'Could not load states.',
    );
  }
}

class _DistrictPlaceList extends StatelessWidget {
  const _DistrictPlaceList({
    required this.districts,
    required this.query,
    required this.failed,
  });

  final List<DistrictModel> districts;
  final String query;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final rows = <_PlaceRow>[
      for (final district in districts)
        if (query.isEmpty ||
            district.districtName.toLowerCase().contains(query) ||
            (district.stateName ?? '').toLowerCase().contains(query))
          _PlaceRow(
            title: district.districtName,
            subtitle: district.stateName ?? '',
          ),
    ];
    return _PlaceList(
      rows: rows,
      searching: query.isNotEmpty,
      failed: failed,
      emptyLabel: 'No districts found.',
      failedLabel: 'Could not load districts.',
    );
  }
}

class _CityPlaceList extends StatelessWidget {
  const _CityPlaceList({
    required this.cities,
    required this.query,
    required this.failed,
  });

  final List<CityModel> cities;
  final String query;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final rows = <_PlaceRow>[
      for (final city in cities)
        if (query.isEmpty ||
            city.cityName.toLowerCase().contains(query) ||
            city.districtName.toLowerCase().contains(query) ||
            city.stateName.toLowerCase().contains(query) ||
            city.pincode.toLowerCase().contains(query))
          _PlaceRow(
            title: city.cityName,
            subtitle: [
              if (city.districtName.isNotEmpty) city.districtName,
              if (city.stateName.isNotEmpty) city.stateName,
            ].join(' · '),
            badge: city.pincode,
          ),
    ];
    return _PlaceList(
      rows: rows,
      searching: query.isNotEmpty,
      failed: failed,
      emptyLabel: 'No cities found.',
      failedLabel: 'Could not load cities.',
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.rows,
    required this.searching,
    required this.failed,
    required this.emptyLabel,
    required this.failedLabel,
  });

  final List<_PlaceRow> rows;
  final bool searching;
  final bool failed;
  final String emptyLabel;
  final String failedLabel;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      final title = failed
          ? failedLabel
          : searching
          ? 'No matches'
          : emptyLabel;
      final message = failed
          ? 'Refresh the dashboard and try again.'
          : searching
          ? 'Try another name, code, or pincode.'
          : 'Nothing is listed here yet.';
      return _EmptyState(
        icon: failed ? Icons.cloud_off_outlined : Icons.search_off,
        title: title,
        message: message,
      );
    }

    final items = <Object>[_sectionLetter(rows.first.title)];
    var lastLetter = items.first as String;
    for (final row in rows) {
      final letter = _sectionLetter(row.title);
      if (letter != lastLetter) {
        items.add(letter);
        lastLetter = letter;
      }
      items.add(row);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, index == 0 ? 4 : 14, 20, 4),
            child: Text(
              item,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          );
        }
        final row = item as _PlaceRow;
        final badge = row.badge.trim();
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    if (row.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        row.subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

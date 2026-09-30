import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../common/app_text_field.dart';
import '../common/brand.dart';

/// Bottom sheet that searches places with Nominatim.
class DestinationSearchSheet extends StatefulWidget {
  const DestinationSearchSheet({
    super.key,
    required this.onSelected,
    this.near,
  });

  final void Function(LatLng location, String name) onSelected;

  /// Where the driver is: nearby matches are listed first.
  final LatLng? near;

  @override
  State<DestinationSearchSheet> createState() => _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends State<DestinationSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _failed = false;
  List<dynamic> _results = [];

  /// Drops answers to searches that a newer one replaced.
  int _request = 0;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    final request = ++_request;
    setState(() => _isSearching = true);

    final near = widget.near;
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.trim(),
      'format': 'json',
      'limit': '8',
      'countrycodes': 'ly',
      'addressdetails': '1',
      'accept-language': Localizations.localeOf(context).languageCode,
      // Prefer matches within about 50 km without excluding the rest.
      if (near != null) ...{
        'viewbox':
            '${near.longitude - 0.5},${near.latitude + 0.5},'
            '${near.longitude + 0.5},${near.latitude - 0.5}',
        'bounded': '0',
      },
    });

    try {
      final response = await http
          .get(
            url,
            headers: {'User-Agent': 'com.example.yaqdah_app_student_project'},
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted || request != _request) return;
      final ok = response.statusCode == 200;
      setState(() {
        _results = ok ? json.decode(response.body) as List<dynamic> : [];
        _failed = !ok;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      debugPrint("Search Error: $e");
      if (!mounted || request != _request) return;
      setState(() {
        _results = [];
        _failed = true;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: AppTextField(
                controller: _controller,
                hint: l10n.searchPlaces,
                leadingIcon: Symbols.search_rounded,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                fill: c.bg,
              ),
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Expanded(
              child: _hasSearched && _results.isEmpty && !_isSearching
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _failed ? l10n.restLoadFailed : l10n.searchNoResults,
                          textAlign: TextAlign.center,
                          style: AppFonts.body(context, 15, color: c.subtext),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => Divider(color: c.line),
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        final fullAddress = result['display_name'].toString();
                        final name = fullAddress.split(',').first;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final lat = double.parse(result['lat']);
                            final lon = double.parse(result['lon']);
                            Navigator.pop(context);
                            widget.onSelected(LatLng(lat, lon), name);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                IconTile(
                                  icon: Symbols.location_on_rounded,
                                  background: c.surface2,
                                  foreground: c.subtext,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.body(
                                          context,
                                          16,
                                          weight: FontWeight.w700,
                                          color: c.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        fullAddress,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.body(
                                          context,
                                          14,
                                          color: c.subtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

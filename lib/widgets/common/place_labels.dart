import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../l10n/app_localizations.dart';
import '../../services/places_service.dart';

/// Icons and labels for [Place] types, shared by the Rest tab and the
/// drowsy alert.
extension PlaceLabels on Place {
  IconData get icon => switch (type) {
    PlaceType.hotel => Symbols.hotel_rounded,
    PlaceType.cafe => Symbols.local_cafe_rounded,
    PlaceType.mosque => Symbols.mosque_rounded,
    PlaceType.fuel => Symbols.local_gas_station_rounded,
    PlaceType.restArea => Symbols.airline_seat_recline_normal_rounded,
    _ => Symbols.location_on_rounded,
  };

  String typeLabel(AppLocalizations l10n) => switch (type) {
    PlaceType.hotel => l10n.placeHotel,
    PlaceType.cafe => l10n.placeCafe,
    PlaceType.mosque => l10n.placeMosque,
    PlaceType.fuel => l10n.placeFuel,
    PlaceType.restArea => l10n.placeRestArea,
    _ => l10n.placeOther,
  };

  /// The place's name, or its type when OpenStreetMap has none.
  String displayName(AppLocalizations l10n) => name ?? typeLabel(l10n);
}

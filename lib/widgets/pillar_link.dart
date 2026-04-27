import 'package:flutter/material.dart';
import '../screens/contacts/contact_show_screen.dart';
import '../screens/deals/deal_show_screen.dart';
import '../screens/properties/property_edit_screen.dart';

/// Navigates to the first non-null pillar destination, following the
/// cockpit fallback order: property → deal → contact.
///
/// Returns `true` if navigation happened. If every id is null the caller
/// should render plain (non-tappable) text rather than a dead link.
bool navigateToPillar(
  BuildContext context, {
  int? propertyId,
  int? dealId,
  int? contactId,
}) {
  if (propertyId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PropertyEditScreen(propertyId: propertyId)),
    );
    return true;
  }
  if (dealId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DealShowScreen(dealId: dealId)),
    );
    return true;
  }
  if (contactId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContactShowScreen(contactId: contactId)),
    );
    return true;
  }
  return false;
}

/// True when at least one pillar FK is populated — use to decide whether to
/// render a row's title / address as a tappable link versus plain text.
bool hasPillarLink({int? propertyId, int? dealId, int? contactId}) =>
    propertyId != null || dealId != null || contactId != null;

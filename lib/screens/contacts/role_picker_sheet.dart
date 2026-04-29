import 'package:flutter/material.dart';
import '../../theme.dart';

const _roles = <Map<String, String>>[
  {'value': 'seller', 'label': 'Seller'},
  {'value': 'landlord', 'label': 'Landlord'},
  {'value': 'buyer', 'label': 'Buyer'},
  {'value': 'tenant', 'label': 'Tenant'},
];

/// Bottom-sheet role picker for the "Create Listing for this contact" flow.
/// Returns the selected role's submit value (e.g. "seller") or null on cancel.
Future<String?> showRolePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Pick contact role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(ctx),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textPrimary(ctx)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          ..._roles.map(
            (r) => ListTile(
              title: Text(
                r['label']!,
                style: TextStyle(color: AppTheme.textPrimary(ctx)),
              ),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted(ctx)),
              onTap: () => Navigator.of(ctx).pop(r['value']),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

/// Slide-up sheet asking why this property isn't for the client.
/// Returns the entered note on Send (may be empty), or null on Cancel.
Future<String?> showNotForMeSheet(BuildContext context,
    {String? initialNote}) async {
  final controller = TextEditingController(text: initialNote ?? '');
  bool sent = false;

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Not for me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              maxLines: 4,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'Tell us why (optional)',
                hintText: 'e.g. Too far from school',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        sent = true;
                        Navigator.pop(ctx, controller.text.trim());
                      },
                      child: const Text('Send'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  controller.dispose();
  return sent ? (result ?? '') : null;
}

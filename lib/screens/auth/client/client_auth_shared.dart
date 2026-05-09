import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Best-effort device label for the `device_name` field on /password/set
// and /login. Used to label tokens server-side ("iPhone 15 — André").
String defaultDeviceName() {
  if (kIsWeb) return 'CoreX Mobile (Web)';
  try {
    if (Platform.isIOS) return 'CoreX Mobile (iOS)';
    if (Platform.isAndroid) return 'CoreX Mobile (Android)';
  } catch (_) {}
  return 'CoreX Mobile';
}

void showAuthToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ),
  );
}

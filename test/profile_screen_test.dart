import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:corex_mobile/models/agent_profile.dart';
import 'package:corex_mobile/providers/auth_provider.dart';
import 'package:corex_mobile/screens/agent_details_screen.dart';
import 'package:corex_mobile/screens/profile_screen.dart';
import 'package:corex_mobile/services/api_service.dart';

class _FakeApi extends ApiService {
  Map<String, dynamic> payload;
  _FakeApi(this.payload);

  /// Every PATCH the screen sent, so a test can assert one was *not* sent.
  final List<Map<String, String?>> updates = [];

  /// Set to make the next update 422 with these field errors.
  Map<String, String>? rejectWith;

  @override
  Future<AgentProfile> getAgentProfile() async =>
      AgentProfile.fromJson(payload);

  @override
  Future<AgentProfile> updateAgentProfile({
    required String cell,
    String? whatsappNumber,
    String? ffcNumber,
    String? facebookUrl,
    String? instagramUrl,
  }) async {
    updates.add({
      'cell': cell,
      'whatsapp_number': whatsappNumber,
      'ffc_number': ffcNumber,
      'website_social_facebook': facebookUrl,
      'website_social_instagram': instagramUrl,
    });
    if (rejectWith != null) {
      throw ValidationException('The given data was invalid.', rejectWith!);
    }
    payload = {
      ...payload,
      'cell': cell,
      'whatsapp_number': whatsappNumber,
      'ffc_number': ffcNumber,
      'website_social_facebook': facebookUrl,
      'website_social_instagram': instagramUrl,
    };
    return AgentProfile.fromJson(payload);
  }
}

Map<String, dynamic> _payload({bool canEdit = true, String? url}) => {
      'id': 5,
      'name': 'Andre Agent',
      'email': 'andre@example.com',
      'role': 'agent',
      'role_label': 'Agent',
      'cell': '0821234567',
      'whatsapp_number': '0821234567',
      'ffc_number': 'FF123456',
      'website_social_facebook': 'https://facebook.com/andre.agent',
      'website_social_instagram': 'https://instagram.com/andre.agent',
      'public_profile_url': url,
      'can_edit': canEdit,
    };

const _url = 'https://qatesting2.corexos.co.za/corex/agents/andre/9kkpazukgy';

Widget _wrapDetails(_FakeApi api) => MaterialApp(
      theme: ThemeData.dark(),
      home: AgentDetailsScreen(api: api),
    );

Widget _wrapProfile(_FakeApi api) => ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: ProfileScreen(api: api),
      ),
    );

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpDetails(WidgetTester tester, _FakeApi api) async {
  _useTallViewport(tester);
  await tester.pumpWidget(_wrapDetails(api));
  await tester.pump();
  await tester.pump();
}

TextField _field(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey('profile-field-$key')));

void main() {
  group('ProfileScreen (Me tab)', () {
    testWidgets('keeps the form off the page and opens it from a tile',
        (tester) async {
      final api = _FakeApi(_payload(url: _url));
      _useTallViewport(tester);
      await tester.pumpWidget(_wrapProfile(api));
      await tester.pump();

      // No inputs on the Me tab itself — that's the whole point of the split.
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('profile-agent-details')),
          findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('profile-agent-details')));
      await tester.pumpAndSettle();

      expect(find.byType(AgentDetailsScreen), findsOneWidget);
      expect(_field(tester, 'cell').controller!.text, '0821234567');
    });
  });

  group('AgentDetailsScreen', () {
    testWidgets('loads the five fields from the API', (tester) async {
      final api = _FakeApi(_payload(url: _url));
      await _pumpDetails(tester, api);

      expect(_field(tester, 'ffc_number').controller!.text, 'FF123456');
      expect(_field(tester, 'cell').controller!.text, '0821234567');
      expect(
          _field(tester, 'whatsapp_number').controller!.text, '0821234567');
      expect(_field(tester, 'website_social_facebook').controller!.text,
          'https://facebook.com/andre.agent');
      expect(_field(tester, 'website_social_instagram').controller!.text,
          'https://instagram.com/andre.agent');

      expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);
      final preview = tester.widget<OutlinedButton>(
          find.byKey(const ValueKey('profile-preview')));
      expect(preview.enabled, isTrue);
    });

    testWidgets(
        'clearing Cell and saving shows the required error and sends nothing',
        (tester) async {
      final api = _FakeApi(_payload(url: _url));
      await _pumpDetails(tester, api);

      await tester.enterText(
          find.byKey(const ValueKey('profile-field-cell')), '');
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pump();

      expect(find.text('Cell number is required.'), findsOneWidget);
      expect(api.updates, isEmpty,
          reason: 'a blank cell must never reach the server');
      // Server-side value untouched.
      expect(api.payload['cell'], '0821234567');
    });

    testWidgets('saves edited fields and shows the server-side response',
        (tester) async {
      final api = _FakeApi(_payload(url: _url));
      await _pumpDetails(tester, api);

      await tester.enterText(
          find.byKey(const ValueKey('profile-field-ffc_number')), 'FF999');
      await tester.enterText(
          find.byKey(const ValueKey('profile-field-website_social_instagram')),
          '');
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pump();
      await tester.pump();

      expect(api.updates, hasLength(1));
      expect(api.updates.single['ffc_number'], 'FF999');
      expect(api.updates.single['cell'], '0821234567');
      // Blank is sent as an empty string so the server clears the column.
      expect(api.updates.single['website_social_instagram'], '');
      expect(find.text('Profile saved.'), findsOneWidget);
    });

    testWidgets('server 422 lands inline on the offending field',
        (tester) async {
      final api = _FakeApi(_payload(url: _url))
        ..rejectWith = {
          'whatsapp_number': 'Must be a South African mobile number.'
        };
      await _pumpDetails(tester, api);

      await tester.enterText(
          find.byKey(const ValueKey('profile-field-whatsapp_number')),
          '12345');
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Must be a South African mobile number.'),
          findsOneWidget);
      // Typing again clears the stale error.
      await tester.enterText(
          find.byKey(const ValueKey('profile-field-whatsapp_number')),
          '0821');
      await tester.pump();
      expect(
          find.text('Must be a South African mobile number.'), findsNothing);
    });

    testWidgets('can_edit=false renders read-only with no Save button',
        (tester) async {
      final api = _FakeApi(_payload(canEdit: false, url: _url));
      await _pumpDetails(tester, api);

      expect(find.byKey(const ValueKey('profile-save')), findsNothing);
      expect(_field(tester, 'cell').enabled, isFalse);
      expect(_field(tester, 'ffc_number').enabled, isFalse);
      // Preview still works for a viewer.
      final preview = tester.widget<OutlinedButton>(
          find.byKey(const ValueKey('profile-preview')));
      expect(preview.enabled, isTrue);
    });

    testWidgets('preview is disabled when the API sends no public URL',
        (tester) async {
      final api = _FakeApi(_payload(url: null));
      await _pumpDetails(tester, api);

      final preview = tester.widget<OutlinedButton>(
          find.byKey(const ValueKey('profile-preview')));
      expect(preview.enabled, isFalse);
    });
  });
}

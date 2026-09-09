import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corex_mobile/models/contact.dart';
import 'package:corex_mobile/models/contact_notes_testimonials.dart';
import 'package:corex_mobile/screens/contacts/contact_show_screen.dart';
import 'package:corex_mobile/services/api_service.dart';

class _FakeApi extends ApiService {
  Contact? contact;
  List<ContactNote> notes = const [];
  List<ContactTestimonial> testimonials = const [];

  /// When true, every write (create/update/delete) 403s — the
  /// assistant-narrower-than-view case.
  bool forbidWrites = false;

  @override
  Future<Contact> getContact(int id) async {
    if (contact == null) throw ApiException(404, 'not found');
    return contact!;
  }

  @override
  Future<List<ContactNote>> getContactNotes(int contactId) async => notes;

  @override
  Future<List<ContactTestimonial>> getContactTestimonials(int contactId) async =>
      testimonials;

  @override
  Future<ContactNote> createContactNote(int contactId,
      {String? type, String? body}) async {
    if (forbidWrites) {
      throw ApiException(403, "You don't have permission to edit this contact.");
    }
    return ContactNote(
      id: 99,
      contactId: contactId,
      type: type,
      body: body,
      userId: 1,
      userName: 'Jane Agent',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

Contact _contact() => const Contact(id: 5, firstName: 'John', lastName: 'Owner');

Widget _wrap(Widget child) => MaterialApp(theme: ThemeData.dark(), home: child);

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _openNotesTab(WidgetTester tester) async {
  final tab = find.byWidgetPredicate((w) => w is Tab && (w.text ?? '') == 'Notes');
  expect(tab, findsOneWidget, reason: 'no "Notes" tab on screen');
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty Notes tab shows both empty states', (tester) async {
    _useTallViewport(tester);
    final api = _FakeApi()..contact = _contact();

    await tester.pumpWidget(_wrap(ContactShowScreen(contactId: 5, api: api)));
    await tester.pumpAndSettle();
    await _openNotesTab(tester);

    expect(find.text('No notes yet.'), findsOneWidget);
    expect(find.text('No testimonials yet.'), findsOneWidget);
  });

  testWidgets('adding a note shows it optimistically then keeps the server copy',
      (tester) async {
    _useTallViewport(tester);
    final api = _FakeApi()..contact = _contact();

    await tester.pumpWidget(_wrap(ContactShowScreen(contactId: 5, api: api)));
    await tester.pumpAndSettle();
    await _openNotesTab(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add Note'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Contacted'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Called about the viewing.');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    // Reconciled with the server response (author name only known post-save).
    expect(find.text('Called about the viewing.'), findsOneWidget);
    expect(find.text('Contacted'), findsOneWidget);
    expect(find.text('Jane Agent'), findsOneWidget);
  });

  testWidgets('a 403 on add disables editing and reverts the optimistic note',
      (tester) async {
    _useTallViewport(tester);
    final api = _FakeApi()
      ..contact = _contact()
      ..forbidWrites = true;

    await tester.pumpWidget(_wrap(ContactShowScreen(contactId: 5, api: api)));
    await tester.pumpAndSettle();
    await _openNotesTab(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add Note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Should fail.');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Should fail.'), findsNothing);
    expect(find.text("You don't have permission to edit this contact."), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, 'Add Note'), findsOneWidget);
    final addNoteButton =
        tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Add Note'));
    expect(addNoteButton.onPressed, isNull);
  });
}

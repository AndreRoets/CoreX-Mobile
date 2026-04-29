import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

const Color _kDanger = Color(0xFFDC2626);

class EditContactScreen extends StatefulWidget {
  final Contact contact;
  const EditContactScreen({super.key, required this.contact});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final ApiService _api = ApiService();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _idNumber;
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.contact.firstName);
    _lastName = TextEditingController(text: widget.contact.lastName);
    _phone = TextEditingController(text: widget.contact.phone ?? '');
    _email = TextEditingController(text: widget.contact.email ?? '');
    _idNumber = TextEditingController(text: widget.contact.idNumber ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _fieldErrors = const {};
    });
    try {
      final updated = await _api.updateContact(widget.contact.id, {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_idNumber.text.trim().isNotEmpty) 'id_number': _idNumber.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = e.fieldErrors;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Contact')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _label('First Name', required: true),
          _field(_firstName, 'first_name', action: TextInputAction.next),
          _label('Last Name', required: true),
          _field(_lastName, 'last_name', action: TextInputAction.next),
          _label('Phone', required: true),
          _field(_phone, 'phone',
              keyboard: TextInputType.phone, action: TextInputAction.next),
          _label('Email'),
          _field(_email, 'email',
              keyboard: TextInputType.emailAddress,
              action: TextInputAction.next),
          _label('ID Number'),
          _field(_idNumber, 'id_number', action: TextInputAction.done),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: RichText(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary(context),
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: _kDanger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : const [],
          ),
        ),
      );

  Widget _field(TextEditingController c, String field,
      {TextInputType? keyboard, TextInputAction? action}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      textInputAction: action,
      decoration: InputDecoration(errorText: _fieldErrors[field]),
      onChanged: (_) {
        if (_fieldErrors.containsKey(field)) {
          setState(() => _fieldErrors = {..._fieldErrors}..remove(field));
        }
      },
    );
  }
}

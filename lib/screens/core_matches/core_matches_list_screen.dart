import 'package:flutter/material.dart';
import '../../models/core_match.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../contacts/contact_show_screen.dart';
import 'core_match_detail_screen.dart';
import 'core_matches_common.dart';

class CoreMatchesListScreen extends StatefulWidget {
  const CoreMatchesListScreen({super.key});

  @override
  State<CoreMatchesListScreen> createState() => _CoreMatchesListScreenState();
}

class _CoreMatchesListScreenState extends State<CoreMatchesListScreen> {
  final ApiService _api = ApiService();
  List<CoreMatchGroup> _groups = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await _api.listCoreMatches();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openMatch(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CoreMatchDetailScreen(matchId: id)),
    ).then((_) => _load());
  }

  void _openContact(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContactShowScreen(contactId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core Matches')),
      body: RefreshIndicator(
        color: AppTheme.brand,
        backgroundColor: AppTheme.surface(context),
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 32, color: AppTheme.textSecondary(context)),
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary(context))),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }
    if (_groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite_rounded,
                      color: AppTheme.brand, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  'No core matches yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create one from a contact to start tracking buyer criteria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _groups.length,
      itemBuilder: (_, i) => _groupSection(_groups[i]),
    );
  }

  Widget _groupSection(CoreMatchGroup g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => _openContact(g.contact.id),
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 16, color: AppTheme.textSecondary(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    g.contact.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (g.contact.phone != null && g.contact.phone!.isNotEmpty)
                  Flexible(
                    child: Text(
                      g.contact.phone!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppTheme.textMuted(context)),
              ],
            ),
          ),
        ),
        ...g.matches.map(_matchTile),
      ],
    );
  }

  Widget _matchTile(CoreMatchSummary m) {
    final fs = m.feedbackSummary;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => _openMatch(m.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusPill(m.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _counter(kReactionInterested, fs.interested),
                      const SizedBox(width: 12),
                      _counter(kReactionNotInterested, fs.notInterested),
                      const SizedBox(width: 12),
                      _counter(kReactionSaved, fs.saved),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted(context)),
          ],
        ),
      ),
    );
  }

  Widget _counter(Color c, int n) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$n',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_models.dart';
import '../../providers/client_session_provider.dart';
import '../../services/api_service.dart' show ApiException;
import '../../services/client_auth_service.dart';
import '../auth/client/client_agency_picker_screen.dart';
import 'client_match_detail_screen.dart';
import 'client_settings_screen.dart';

// The post-login client home — Core Matches list scoped to the currently
// selected agency.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _api = ClientAuthService();

  bool _loading = true;
  String? _error;
  List<ClientMatch> _matches = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = context.read<ClientSessionProvider>();
    // Refresh /me first so locked/current agency stay in sync. Failures here
    // are non-fatal — we'll surface a /matches error instead.
    await session.refreshMe();
    if (!mounted) return;

    try {
      final result = await _api.matches();
      if (!mounted) return;
      setState(() {
        _matches = result.matches;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await session.signOutLocal();
        return;
      }
      if (e.statusCode == 409) {
        // No agency selected — kick to picker.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ClientAgencyPickerScreen(initialPick: true),
          ),
        );
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load matches. Pull to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClientSessionProvider>();
    final agency = session.currentAgency;
    final canSwitch = session.agencies.length > 1 &&
        session.client?.lockedToAgencyId == null;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: canSwitch
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const ClientAgencyPickerScreen(initialPick: false),
                    ),
                  )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  agency?.name ?? 'CoreX',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canSwitch)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.expand_more, size: 20),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ClientSettingsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await session.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _matches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _matches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 64),
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
        ],
      );
    }
    if (_matches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 64),
          Icon(Icons.search_off,
              size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          const Text(
            'No Core Matches yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Your agent hasn't set up any matches for you yet. Check back soon.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MatchCard(
        match: _matches[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientMatchDetailScreen(match: _matches[i]),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final ClientMatch match;
  final VoidCallback onTap;
  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbs = match.results.take(3).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _matchTitle(match),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${match.resultCount} result${match.resultCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (thumbs.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      for (var i = 0; i < thumbs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: _Thumb(url: thumbs[i].thumbnail)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _matchTitle(ClientMatch m) {
    final type = (m.listingType ?? '').isNotEmpty
        ? m.listingType![0].toUpperCase() + m.listingType!.substring(1)
        : 'Match';
    return '$type · #${m.id}';
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: (url == null || url!.isEmpty)
            ? Center(
                child: Icon(Icons.home_outlined,
                    color: Theme.of(context).hintColor),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Theme.of(context).hintColor),
                ),
              ),
      ),
    );
  }
}

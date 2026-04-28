import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/property_overview.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'property_edit_screen.dart';

class PropertyOverviewScreen extends StatefulWidget {
  final int propertyId;
  final ApiService? api;

  const PropertyOverviewScreen({
    super.key,
    required this.propertyId,
    this.api,
  });

  @override
  State<PropertyOverviewScreen> createState() => _PropertyOverviewScreenState();
}

class _PropertyOverviewScreenState extends State<PropertyOverviewScreen> {
  late final ApiService _api = widget.api ?? ApiService();
  PropertyOverview? _data;
  bool _loading = true;
  String? _error;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final d = await _api.getPropertyOverview(widget.propertyId,
          forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _error = e.message;
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

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PropertyEditScreen(propertyId: widget.propertyId),
                ),
              );
              if (mounted) _load(forceRefresh: true);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: () => _load(forceRefresh: true))
              : RefreshIndicator(
                  onRefresh: () => _load(forceRefresh: true),
                  child: _buildBody(_data!),
                ),
    );
  }

  Widget _buildBody(PropertyOverview p) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _hero(p),
        const SizedBox(height: 16),
        _atAGlance(p),
        const SizedBox(height: 16),
        if ((p.description ?? '').isNotEmpty) ...[
          _sectionTitle('Description'),
          _description(p.description!),
          const SizedBox(height: 16),
        ],
        if ((p.livePreviewUrl ?? '').isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Live Preview'),
              onPressed: () => _open(p.livePreviewUrl),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _sectionTitle('Where this listing is published'),
        const SizedBox(height: 8),
        _placementsBlock(p.placements),
        const SizedBox(height: 16),
        if (p.agent != null) ...[
          _sectionTitle('Listing Agent'),
          const SizedBox(height: 8),
          _contactCard(p.agent!),
          const SizedBox(height: 16),
        ],
        if (p.owner != null) ...[
          _sectionTitle('Owner'),
          const SizedBox(height: 8),
          _contactCard(p.owner!, onTap: p.owner!.id != null ? () {} : null),
          const SizedBox(height: 16),
        ],
        if ((p.virtualTourUrl ?? '').isNotEmpty) ...[
          _sectionTitle('Virtual Tour'),
          const SizedBox(height: 8),
          _virtualTourCard(p.virtualTourUrl!),
          const SizedBox(height: 16),
        ],
        _sectionTitle('Key dates'),
        const SizedBox(height: 8),
        _keyDatesGrid(p.keyDates),
      ],
    );
  }

  Widget _hero(PropertyOverview p) {
    final hasImage = (p.coverImage ?? '').isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.surface2(context),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(p.coverImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35), BlendMode.darken),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if ((p.status ?? '').isNotEmpty) _statusPill(p.status!),
                  const Spacer(),
                  if (p.daysOnMarket != null)
                    _chip('${p.daysOnMarket} days on market'),
                ],
              ),
              const Spacer(),
              Text(
                p.title ?? 'Untitled',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                [p.suburb, p.city].where((e) => (e ?? '').isNotEmpty).join(', '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.priceDisplay ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _atAGlance(PropertyOverview p) {
    final items = <String>[];
    if (p.beds != null) items.add('${p.beds} Beds');
    if (p.baths != null) items.add('${p.baths} Baths');
    if (p.garages != null) items.add('${p.garages} Garages');
    if ((p.sizeM2 ?? '').isNotEmpty) items.add('${p.sizeM2} m² floor');
    if ((p.erfSizeM2 ?? '').isNotEmpty) items.add('${p.erfSizeM2} m² erf');
    if (p.photosCount != null) items.add('${p.photosCount} Photos');
    if ((p.mandateType ?? '').isNotEmpty) items.add('${p.mandateType} mandate');

    if (items.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Text(items[i],
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('·',
                    style: TextStyle(color: AppTheme.textMuted(context))),
              ),
          ],
        ],
      ),
    );
  }

  Widget _description(String text) {
    const limit = 220;
    final isLong = text.length > limit;
    final shown = !isLong || _descExpanded ? text : '${text.substring(0, limit).trimRight()}…';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shown,
            style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 14,
                height: 1.4)),
        if (isLong)
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTheme.brand,
            ),
            onPressed: () =>
                setState(() => _descExpanded = !_descExpanded),
            child: Text(_descExpanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }

  Widget _placementsBlock(List<Placement> placements) {
    if (placements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_off,
                      size: 18, color: AppTheme.textMuted(context)),
                  const SizedBox(width: 8),
                  Text('Not yet published',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      )),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "This listing isn't published anywhere yet — open Syndication on the desktop to publish.",
                style: TextStyle(
                    color: AppTheme.textSecondary(context), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: placements.map(_placementCard).toList(),
    );
  }

  IconData _portalIcon(String key) {
    switch (key) {
      case 'hfc_premium':
        return Icons.star_rounded;
      case 'private_property':
        return Icons.home_work_outlined;
      case 'property24':
        return Icons.public;
      default:
        return Icons.language;
    }
  }

  Widget _placementCard(Placement p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => _open(p.url),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Icon(_portalIcon(p.key),
                    color: AppTheme.brand, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        )),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.live)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text('View on portal',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.brand,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new,
                  size: 16, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactCard(ContactRef c, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _avatar(c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context)),
                    ),
                    if ((c.phone ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _open('tel:${c.phone}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 14, color: AppTheme.brand),
                              const SizedBox(width: 6),
                              Text(c.phone!,
                                  style: const TextStyle(
                                      color: AppTheme.brand,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    if ((c.email ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => _open('mailto:${c.email}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined,
                                  size: 14, color: AppTheme.brand),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(c.email!,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppTheme.brand,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(ContactRef c) {
    if ((c.photoUrl ?? '').isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(c.photoUrl!,
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsAvatar(c.name)),
      );
    }
    return _initialsAvatar(c.name);
  }

  Widget _initialsAvatar(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts.first.isEmpty
                ? '?'
                : parts.first[0].toUpperCase()
            : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _virtualTourCard(String url) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => _open(url),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.threesixty, color: AppTheme.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Virtual Tour',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context))),
              ),
              Icon(Icons.open_in_new,
                  size: 16, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyDatesGrid(KeyDates kd) {
    final tiles = [
      _KeyDateTile('Listed', kd.listed),
      _KeyDateTile('Expires', kd.expires),
      _KeyDateTile('Loaded', _relative(kd.loaded)),
      _KeyDateTile('Modified', _relative(kd.modified)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: tiles
          .map((t) => Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 4),
                      Text(t.value ?? '—',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context))),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  String? _relative(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            )),
      );
}

class _KeyDateTile {
  final String label;
  final String? value;
  _KeyDateTile(this.label, this.value);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: AppTheme.textMuted(context)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary(context))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

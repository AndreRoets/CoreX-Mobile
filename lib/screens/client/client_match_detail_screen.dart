import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/client_models.dart';

class ClientMatchDetailScreen extends StatelessWidget {
  final ClientMatch match;
  const ClientMatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final results = match.results;
    final type = (match.listingType ?? '').isNotEmpty
        ? match.listingType![0].toUpperCase() + match.listingType!.substring(1)
        : 'Match';

    return Scaffold(
      appBar: AppBar(title: Text('$type · #${match.id}')),
      body: results.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No results in this match yet.'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ResultRow(result: results[i]),
            ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ClientMatchResultThumb result;
  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // Public listing pages live on the agency site — open externally.
          // For now, do nothing if no URL is available.
          final uri = Uri.tryParse(result.thumbnail ?? '');
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: (result.thumbnail == null ||
                        result.thumbnail!.isEmpty)
                    ? Center(
                        child: Icon(Icons.home_outlined,
                            color: Theme.of(context).hintColor),
                      )
                    : Image.network(
                        result.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Theme.of(context).hintColor),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.address,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (result.suburb != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.suburb!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (result.beds != null)
                          _Tag(text: '${result.beds} bd'),
                        if (result.baths != null)
                          _Tag(text: '${result.baths} ba'),
                        if (result.price != null)
                          _Tag(text: 'R ${_money(result.price!)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _money(num n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && (fromEnd - 1) % 3 == 0) buf.write(' ');
    }
    return buf.toString();
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

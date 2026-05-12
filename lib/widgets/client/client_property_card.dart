import 'package:flutter/material.dart';

import '../../models/client_models.dart';
import '../../theme.dart';
import 'reaction_bar.dart';

class ClientPropertyCard extends StatelessWidget {
  final ClientMatchResult result;
  final VoidCallback onTap;
  final void Function(String reaction) onReact;

  const ClientPropertyCard({
    super.key,
    required this.result,
    required this.onTap,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final price = result.priceDisplay ??
        (result.price != null ? 'R ${_money(result.price!)}' : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with overlays.
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (result.thumbnail != null && result.thumbnail!.isNotEmpty)
                    Image.network(
                      result.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surface2(context),
                        child: Icon(Icons.broken_image_outlined,
                            color: AppTheme.textMuted(context)),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surface2(context),
                      child: Icon(Icons.home_outlined,
                          color: AppTheme.textMuted(context), size: 36),
                    ),
                  if (result.matchScore != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${result.matchScore}% match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (result.reaction != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: reactionPill(context, result.reaction),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (price != null)
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brand,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    result.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (result.suburb != null && result.suburb!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        result.suburb!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (result.beds != null) ...[
                        Icon(Icons.bed_rounded,
                            size: 14, color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 2),
                        Text('${result.beds}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                      if (result.baths != null) ...[
                        Icon(Icons.bathtub_outlined,
                            size: 14, color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 2),
                        Text('${result.baths}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                      if (result.garages != null) ...[
                        Icon(Icons.garage_outlined,
                            size: 14, color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 2),
                        Text('${result.garages}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                  if (result.reaction == 'not_interested' &&
                      result.reactionNote != null &&
                      result.reactionNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        result.reactionNote!,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ReactionBar(
              current: result.reaction,
              onInterested: onReact,
              onSaved: onReact,
              onNotForMe: onReact,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _money(num n) {
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

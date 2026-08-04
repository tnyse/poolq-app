import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/utils/avatar_url.dart';

/// Top-3 podium inspired by ranked-leaderboard mockups.
class LeaderboardPodium extends StatelessWidget {
  final List<Map<String, dynamic>> top3;
  final Set<String> reigningChampionUids;
  final int? gamesPlayed;
  final String? subtitle;
  final void Function(Map<String, dynamic> player)? onTap;

  const LeaderboardPodium({
    super.key,
    required this.top3,
    this.reigningChampionUids = const {},
    this.gamesPlayed,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    Map<String, dynamic>? at(int rank) {
      for (final p in top3) {
        final r = (p['rank'] as num?)?.toInt() ?? 0;
        if (r == rank) return p;
      }
      if (rank - 1 < top3.length) return top3[rank - 1];
      return null;
    }

    final first = at(1);
    final second = at(2);
    final third = at(3);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF063a73).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumSlot(
                  player: second,
                  place: 2,
                  accent: const Color(0xFF64B5F6),
                  pillarHeight: 56,
                  avatarSize: 64,
                  showCrown: false,
                  gamesPlayed: gamesPlayed,
                  isReigning: second != null &&
                      reigningChampionUids.contains('${second['uid']}'),
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _PodiumSlot(
                  player: first,
                  place: 1,
                  accent: const Color(0xFFFFD54F),
                  pillarHeight: 84,
                  avatarSize: 78,
                  showCrown: true,
                  gamesPlayed: gamesPlayed,
                  isReigning: first != null &&
                      reigningChampionUids.contains('${first['uid']}'),
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _PodiumSlot(
                  player: third,
                  place: 3,
                  accent: const Color(0xFF69F0AE),
                  pillarHeight: 44,
                  avatarSize: 58,
                  showCrown: false,
                  gamesPlayed: gamesPlayed,
                  isReigning: third != null &&
                      reigningChampionUids.contains('${third['uid']}'),
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final Map<String, dynamic>? player;
  final int place;
  final Color accent;
  final double pillarHeight;
  final double avatarSize;
  final bool showCrown;
  final bool isReigning;
  final int? gamesPlayed;
  final void Function(Map<String, dynamic> player)? onTap;

  const _PodiumSlot({
    required this.player,
    required this.place,
    required this.accent,
    required this.pillarHeight,
    required this.avatarSize,
    required this.showCrown,
    required this.isReigning,
    this.gamesPlayed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return SizedBox(height: pillarHeight + avatarSize + 72);
    }

    final name = (player!['displayName'] ?? 'Player').toString();
    final score = (player!['score'] as num?)?.toInt() ?? 0;
    final pct = (gamesPlayed != null && gamesPlayed! > 0)
        ? ((score / gamesPlayed!) * 100).round()
        : null;
    final uid = (player!['uid'] ?? '').toString();
    final photo = (player!['photoURL'] ?? '').toString();
    final email = (player!['email'] ?? '').toString();

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(player!),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: avatarSize + 22,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (showCrown || isReigning)
                  const Positioned(
                    top: 0,
                    child: Text('👑', style: TextStyle(fontSize: 18)),
                  ),
                Positioned(
                  top: (showCrown || isReigning) ? 16 : 4,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image(
                        image: resolveAvatarImage(
                          photoUrl: photo,
                          email: email.isNotEmpty ? email : '$uid@poolq.app',
                          size: (avatarSize * 2).round(),
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/user.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$place',
                      style: const TextStyle(
                        color: Color(0xFF063a73),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            pct == null ? '$score' : '$score · $pct%',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: pillarHeight,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.55),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
          ),
        ],
      ),
    );
  }
}

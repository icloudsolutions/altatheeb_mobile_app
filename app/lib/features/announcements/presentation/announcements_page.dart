import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/widgets/ems_widgets.dart';
import '../domain/announcement.dart';
import 'announcements_cubit.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.announcementsTitle)),
      body: BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
        builder: (context, state) {
          if (state is AnnouncementsLoading) {
            return const SkeletonList(count: 5);
          }
          if (state is AnnouncementsError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<AnnouncementsCubit>().load(),
              retryLabel: l.retry,
            );
          }
          if (state is AnnouncementsLoaded) {
            if (state.announcements.isEmpty) {
              return EmptyState(
                icon: Icons.campaign_outlined,
                title: l.announcementsEmpty,
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<AnnouncementsCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: state.announcements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _AnnouncementCard(state.announcements[i]),
              ),
            );
          }
          return const SkeletonList();
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatefulWidget {
  const _AnnouncementCard(this.item);
  final Announcement item;

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = widget.item.publishedAt != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(widget.item.publishedAt!)
        : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.item.body != null
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign_outlined, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (widget.item.body != null)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: cs.onSurface.withValues(alpha: .5),
                    ),
                ],
              ),
              if (dateStr != null) ...[
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: .5)),
                ),
              ],
              if (_expanded && widget.item.body != null) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                Text(widget.item.body!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/widgets/ems_widgets.dart';
import '../../children/presentation/children_cubit.dart';
import '../domain/attendance_record.dart';
import 'attendance_cubit.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final childrenState = context.watch<ChildrenCubit>().state;
    final selectedId =
        (childrenState is ChildrenLoaded) ? childrenState.selected?.id : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.attendanceTitle)),
      body: selectedId == null
          ? EmptyState(
              icon: Icons.event_available_outlined,
              title: l.attendanceNoChild,
            )
          : BlocBuilder<AttendanceCubit, AttendanceState>(
              builder: (context, state) {
                if (state is AttendanceLoading) {
                  return const SkeletonList(count: 6);
                }
                if (state is AttendanceError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<AttendanceCubit>().loadFor(selectedId),
                    retryLabel: l.retry,
                  );
                }
                if (state is AttendanceLoaded) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<AttendanceCubit>().loadFor(selectedId),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _SummaryCard(state.summary),
                        ),
                        if (state.summary.records.isEmpty)
                          SliverFillRemaining(
                            child: EmptyState(
                              icon: Icons.event_available_outlined,
                              title: l.attendanceEmpty,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _AttendanceRow(
                                      state.summary.records[i]),
                                ),
                                childCount: state.summary.records.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SkeletonList();
              },
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.summary);
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: l.attendancePresent, value: summary.present, color: Colors.green),
            _Stat(label: l.attendanceAbsent, value: summary.absent, color: cs.error),
            _Stat(label: l.attendanceLate, value: summary.late, color: Colors.orange),
            _Stat(label: l.attendanceExcused, value: summary.excused, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow(this.record);
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (color, label, icon) = switch (record.status) {
      'present' => (
          const Color(0xFF2E7D32),
          l.attendancePresent,
          Icons.check_circle_outline
        ),
      'absent' => (
          const Color(0xFFC62828),
          l.attendanceAbsent,
          Icons.cancel_outlined
        ),
      'late' => (const Color(0xFFF57F17), l.attendanceLate, Icons.schedule),
      _ => (const Color(0xFF1565C0), l.attendanceExcused, Icons.info_outline),
    };
    final dateStr = record.date != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(record.date!)
        : '—';
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(dateStr, style: Theme.of(context).textTheme.titleSmall),
        subtitle: record.remarks != null
            ? Text(record.remarks!,
                style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: StatusBadge(label: label, color: color, small: true),
      ),
    );
  }
}

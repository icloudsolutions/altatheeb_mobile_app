import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/widgets/ems_widgets.dart';
import '../../children/presentation/children_cubit.dart';
import '../domain/exam_result.dart';
import 'results_cubit.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final childrenState = context.watch<ChildrenCubit>().state;
    final selectedId =
        (childrenState is ChildrenLoaded) ? childrenState.selected?.id : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.resultsTitle)),
      body: selectedId == null
          ? EmptyState(
              icon: Icons.bar_chart_outlined,
              title: l.resultsNoChild,
            )
          : BlocBuilder<ResultsCubit, ResultsState>(
              builder: (context, state) {
                if (state is ResultsLoading) {
                  return const SkeletonList(count: 4);
                }
                if (state is ResultsError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () =>
                        context.read<ResultsCubit>().loadFor(selectedId),
                    retryLabel: l.retry,
                  );
                }
                if (state is ResultsLoaded) {
                  if (state.results.isEmpty) {
                    return EmptyState(
                      icon: Icons.bar_chart_outlined,
                      title: l.resultsEmpty,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<ResultsCubit>().loadFor(selectedId),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: state.results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ResultCard(state.results[i]),
                    ),
                  );
                }
                return const SkeletonList();
              },
            ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.result);
  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = result.percentage;
    final gradeColor = pct >= 90
        ? Colors.green
        : pct >= 70
            ? cs.primary
            : pct >= 50
                ? Colors.orange
                : cs.error;
    final dateStr = result.date != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(result.date!)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.examName,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (result.subject != null)
                        Text(result.subject!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurface.withValues(alpha: .6))),
                    ],
                  ),
                ),
                if (result.grade != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.grade!,
                      style: TextStyle(
                          color: gradeColor, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: result.totalMarks > 0 ? pct / 100 : 0,
              backgroundColor: gradeColor.withValues(alpha: .1),
              color: gradeColor,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${result.marksObtained.toStringAsFixed(1)} / ${result.totalMarks.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: gradeColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (dateStr != null) ...[
              const SizedBox(height: 4),
              Text(dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: .5))),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/children/domain/child.dart';
import '../../features/children/presentation/children_cubit.dart';

/// Persistent horizontal child-switcher shown below the app bar.
/// Displays pill-shaped tabs for each child; tapping selects them.
class ChildSelectorBar extends StatelessWidget {
  const ChildSelectorBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChildrenCubit, ChildrenState>(
      builder: (context, state) {
        if (state is! ChildrenLoaded || state.children.length <= 1) {
          return const SizedBox.shrink();
        }
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: state.children
                      .map((c) => _ChildChip(
                            child: c,
                            selected: state.selected?.id == c.id,
                            onTap: () =>
                                context.read<ChildrenCubit>().select(c),
                          ))
                      .toList(),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Child child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: selected
                    ? cs.onPrimary.withValues(alpha: 0.25)
                    : cs.primary.withValues(alpha: 0.15),
                child: Text(
                  child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.onPrimary : cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                child.name.split(' ').first,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

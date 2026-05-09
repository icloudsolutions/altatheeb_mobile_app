import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../invoices/presentation/invoices_page.dart';
import '../../invoices/presentation/invoices_cubit.dart';
import '../../settings/presentation/settings_page.dart';
import 'children_cubit.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<ChildrenCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ChildrenCubit, ChildrenState>(
          listener: (context, state) {
            if (state is ChildrenLoaded && state.selected != null) {
              context.read<InvoicesCubit>().loadFor(state.selected!.id);
            }
          },
          builder: (context, state) {
            return IndexedStack(
              index: _index,
              children: [
                _DashboardPage(state: state),
                const InvoicesPage(),
                const SettingsPage(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home), label: l.homeWelcome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long), label: l.invoicesTitle),
          NavigationDestination(icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings), label: l.settingsTitle),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.state});
  final ChildrenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        AppBar(
          title: Text(l.appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l.logout,
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        ),
        Expanded(
          child: switch (state) {
            ChildrenLoading() => const Center(child: CircularProgressIndicator()),
            ChildrenError(message: final m) => Center(child: Text(m)),
            ChildrenLoaded(children: final list, selected: final sel) =>
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l.childrenTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...list.map((c) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
                          title: Text(c.name),
                          subtitle: Text([
                            if (c.studentNumber != null) c.studentNumber!,
                            if (c.grade != null) c.grade!,
                            if (c.division != null) c.division!,
                          ].join(' · ')),
                          trailing: sel?.id == c.id ? const Icon(Icons.check_circle) : null,
                          onTap: () => context.read<ChildrenCubit>().select(c),
                        ),
                      )),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

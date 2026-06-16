import 'package:flutter/material.dart';

import '../../core/config/app_config_service.dart';

class MaintenanceBanner extends StatelessWidget {
  const MaintenanceBanner({super.key, required this.config, required this.child});

  final AppConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!config.maintenanceEnabled) return child;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr
        ? (config.maintenanceTitleAr ?? config.maintenanceTitleEn)
        : (config.maintenanceTitleEn ?? config.maintenanceTitleAr);
    final body = isAr
        ? (config.maintenanceBodyAr ?? config.maintenanceBodyEn)
        : (config.maintenanceBodyEn ?? config.maintenanceBodyAr);

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer)),
                      if (body != null)
                        Text(body,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

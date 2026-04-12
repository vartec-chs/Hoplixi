import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutLicensesScreen extends StatelessWidget {
  const AboutLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final info = snapshot.data;
        final appName = (info?.appName.isNotEmpty ?? false)
            ? info!.appName
            : 'Hoplixi';
        final version = info?.version ?? '-';
        final buildNumber = info?.buildNumber ?? '-';

        return LicensePage(
          applicationName: appName,
          applicationVersion: '$version ($buildNumber)',
          applicationIcon: const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(Icons.shield_outlined, size: 42),
          ),
        );
      },
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/env/env_config.dart';
import '../widgets/app_toast.dart';

enum LegalPage {
  terms('terms.html'),
  privacy('privacy.html');

  const LegalPage(this.fileName);
  final String fileName;
}

/// Opens a hosted legal page in the browser.
Future<void> openLegalPage(BuildContext context, LegalPage page) async {
  final uri = Uri.parse('${EnvConfig.legalBaseUrl}/${page.fileName}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    AppToast.error(context, 'Could not open the page. Visit $uri');
  }
}

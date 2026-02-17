import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../utils/app_logger.dart';

class NativeDiagnosticsLogsScreen extends StatelessWidget {
  const NativeDiagnosticsLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: talker, appBarTitle: 'Logs');
  }
}

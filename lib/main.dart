import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'amplifyconfiguration.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const ProviderScope(child: MyApp()));
}

/// Initialise Amplify once. Swallows [AmplifyAlreadyConfiguredException]
/// so hot-reloads in development don't crash.
Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyconfig);
    debugPrint('[Amplify] configured ✓');
  } on AmplifyAlreadyConfiguredException {
    debugPrint('[Amplify] already configured — skipping');
  } on AmplifyException catch (e) {
    // Surface config errors so they're visible instead of being silently swallowed
    debugPrint('[Amplify] CONFIGURATION ERROR: ${e.message}');
    debugPrint('[Amplify] Hint: check amplifyconfiguration.dart — PoolId may be invalid');
  } catch (e) {
    debugPrint('[Amplify] Unexpected configuration error: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restore any existing Cognito session before routing
    final authInit = ref.watch(authInitProvider);

    return authInit.when(
      // While checking session: show branded splash
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      // Session check failed: still route normally (user will be on /login)
      error: (_, __) => _buildRouter(ref),
      // Session check done: route based on currentUserProvider
      data: (_) => _buildRouter(ref),
    );
  }

  Widget _buildRouter(WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'BLR Brew Bam',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

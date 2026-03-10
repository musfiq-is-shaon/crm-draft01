import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main/shell_page.dart';
import 'presentation/widgets/loading_widget.dart';

class CRMApp extends ConsumerStatefulWidget {
  const CRMApp({super.key});

  @override
  ConsumerState<CRMApp> createState() => _CRMAppState();
}

class _CRMAppState extends ConsumerState<CRMApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
      ref.read(themeProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return AnimatedTheme(
      data: themeMode == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: MaterialApp(
        title: 'CRM Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home:
            authState.status == AuthStatus.initial ||
                authState.status == AuthStatus.loading
            ? const Scaffold(body: Center(child: LoadingWidget()))
            : authState.status == AuthStatus.authenticated
            ? const ShellPage()
            : const LoginPage(),
      ),
    );
  }
}

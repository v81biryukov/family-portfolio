import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'router/app_router.dart';
import 'providers/theme_provider.dart';
import 'utils/constants.dart';
import 'models/asset_model.dart';
import 'models/exchange_rate_model.dart';
import 'models/settings_model.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  await _registerHiveAdapters();
  
  // Initialize sync service (opens boxes)
  final syncService = SyncService();
  await syncService.initialize();
  
  runApp(
    const ProviderScope(
      child: FamilyPortfolioApp(),
    ),
  );
}

Future<void> _registerHiveAdapters() async {
  // Register adapters for Hive models
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AssetAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ExchangeRateAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(OwnerInfoAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(CurrencyInfoAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(AssetTypeInfoAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(SyncMetadataAdapter());
  }
}

class FamilyPortfolioApp extends ConsumerWidget {
  const FamilyPortfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);
    
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppConstants.lightTheme,
          darkTheme: AppConstants.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}

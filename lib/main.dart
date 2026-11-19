import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/data/repositories.dart';
import 'features/auth/supabase_auth_repository.dart';

// Set via `flutter run --dart-define-from-file=env.json` (gitignored).
// Without them the app runs on the mock AuthRepository.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useSupabase = _supabaseUrl != '' && _supabaseKey != '';
  if (useSupabase) {
    await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  }
  runApp(
    ProviderScope(
      overrides: [
        if (useSupabase)
          authRepositoryProvider.overrideWithValue(
            SupabaseAuthRepository(Supabase.instance.client.auth),
          ),
      ],
      child: const ManisApp(),
    ),
  );
}

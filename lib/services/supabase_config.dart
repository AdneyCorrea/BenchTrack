class SupabaseConfig {
  static const String url =
      'https://mwzbsenbvtvlccnwumkl.supabase.co';

  static const String publishableKey =
      'sb_publishable_7RqK6n5paLBOLGGurxo01w_CAZ3P-4W';

  static bool get isConfigured {
    return url.startsWith('https://') &&
        publishableKey.startsWith('sb_publishable_');
  }
}

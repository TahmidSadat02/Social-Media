import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://szvcogdwiaycvanebokd.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dmNvZ2R3aWF5Y3ZhbmVib2tkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NTU1MDYsImV4cCI6MjA5MTEzMTUwNn0.VakSgW5dYgaAV1syQYjdBCSq2SjaUBYn3EGjJOj8dtE';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}

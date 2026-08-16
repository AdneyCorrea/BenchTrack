import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workstation.dart';

class WorkstationService {
  final SupabaseClient client;

  WorkstationService(this.client);

  Future<List<Workstation>> getWorkstations() async {
    final response = await client
        .from('workstations')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => Workstation.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Workstation> createWorkstation(
    Workstation workstation,
  ) async {
    final data = workstation.toMap();
    data.remove('id');

    final response = await client
        .from('workstations')
        .insert(data)
        .select()
        .single();

    return Workstation.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<Workstation> updateWorkstation(
    Workstation workstation,
  ) async {
    final data = workstation.toMap();
    data.remove('id');

    final response = await client
        .from('workstations')
        .update(data)
        .eq('id', workstation.id)
        .select()
        .single();

    return Workstation.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}

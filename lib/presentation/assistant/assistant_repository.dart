import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'assistant_models.dart';

class AssistantRepository {
  AssistantRepository({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: _functionsRegion),
      _auth = auth ?? FirebaseAuth.instance;

  static const _functionsRegion = 'europe-west1';

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  bool get isSignedIn => _auth.currentUser != null;

  Future<AssistantChatResult> send({
    required String message,
    required List<AssistantChatTurn> history,
    required AssistantContextSnapshot context,
  }) async {
    final result = await _functions.httpsCallable('assistantChat').call({
      'message': message,
      'history': history.map((e) => e.toWire()).toList(),
      'context': context.toWire(),
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final actionsRaw = data['actions'];
    final actions = <AssistantAction>[];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is Map) {
          actions.add(AssistantAction.fromWire(Map<String, dynamic>.from(item)));
        }
      }
    }
    return AssistantChatResult(
      reply: (data['reply'] ?? '').toString().trim(),
      actions: actions,
      remainingToday: (data['remainingToday'] as num?)?.toInt() ?? 0,
    );
  }
}

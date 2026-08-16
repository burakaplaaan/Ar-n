class AssistantChatTurn {
  const AssistantChatTurn({
    required this.role,
    required this.text,
    this.id = 0,
  });

  final String role;
  final String text;
  final int id;

  bool get isUser => role == 'user';

  Map<String, dynamic> toWire() => {'role': role, 'text': text};
}

class AssistantAction {
  const AssistantAction({required this.name, required this.args});

  final String name;
  final Map<String, dynamic> args;

  factory AssistantAction.fromWire(Map<String, dynamic> raw) {
    final argsRaw = raw['args'];
    return AssistantAction(
      name: raw['name']?.toString() ?? '',
      args: argsRaw is Map
          ? Map<String, dynamic>.from(argsRaw)
          : const <String, dynamic>{},
    );
  }
}

class AssistantChatResult {
  const AssistantChatResult({
    required this.reply,
    required this.actions,
    required this.remainingToday,
  });

  final String reply;
  final List<AssistantAction> actions;
  final int remainingToday;
}

class AssistantContextSnapshot {
  const AssistantContextSnapshot({
    this.name,
    this.locale = 'tr',
    this.nextPrayer,
    this.prayers,
    this.habits,
  });

  final String? name;
  final String locale;
  final String? nextPrayer;
  final String? prayers;
  final String? habits;

  Map<String, dynamic> toWire() => {
    if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
    'locale': locale,
    if (nextPrayer != null && nextPrayer!.isNotEmpty) 'nextPrayer': nextPrayer,
    if (prayers != null && prayers!.isNotEmpty) 'prayers': prayers,
    if (habits != null && habits!.isNotEmpty) 'habits': habits,
  };
}

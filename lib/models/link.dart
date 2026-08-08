class Link {
  final String sourceId;
  final String targetId;
  final String? label;

  Link({
    required this.sourceId,
    required this.targetId,
    this.label,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'label': label,
    };
  }

  factory Link.fromMap(Map<String, dynamic> map) {
    return Link(
      sourceId: map['sourceId'],
      targetId: map['targetId'],
      label: map['label'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Link &&
        other.sourceId == sourceId &&
        other.targetId == targetId;
  }

  @override
  int get hashCode => sourceId.hashCode ^ targetId.hashCode;
}

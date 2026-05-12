import 'package:cloud_firestore/cloud_firestore.dart';

class Decision {
  final String id;
  final String text;
  final String owner;
  final DateTime createdAt;

  const Decision({
    required this.id,
    required this.text,
    this.owner = '',
    required this.createdAt,
  });

  factory Decision.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Decision(
      id: doc.id,
      text: data['text'] as String? ?? '',
      owner: data['owner'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Decision.fromMap(String id, Map<String, dynamic> map) {
    return Decision(
      id: id,
      text: map['text'] as String? ?? '',
      owner: map['owner'] as String? ?? '',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'text': text,
        'owner': owner,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

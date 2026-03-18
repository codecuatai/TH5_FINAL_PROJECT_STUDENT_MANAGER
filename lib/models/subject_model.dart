class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.credits,
    required this.score,
    required this.semester,
  });

  final String id;
  final String name;
  final int credits;
  final double score;
  final String semester;

  SubjectModel copyWith({
    String? id,
    String? name,
    int? credits,
    double? score,
    String? semester,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      score: score ?? this.score,
      semester: semester ?? this.semester,
    );
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      semester: (map['semester'] as String?) ?? 'N/A',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'credits': credits,
      'score': score,
      'semester': semester,
    };
  }
}

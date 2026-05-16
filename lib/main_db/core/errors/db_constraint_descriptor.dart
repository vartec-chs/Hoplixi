class DbConstraintDescriptor {
  const DbConstraintDescriptor({
    required this.constraint,
    required this.entity,
    required this.table,
    required this.code,
    required this.message,
    this.field,
  });

  final String constraint;
  final String entity;
  final String table;
  final String code;
  final String message;
  final String? field;
}

class QueryFilters {
  final Map<String, dynamic> values;

  const QueryFilters(this.values);

  bool get isEmpty => values.isEmpty;

  QueryFilters copyWith(Map<String, dynamic> updates) {
    return QueryFilters({
      ...values,
      ...updates,
    });
  }

  Map<String, String> toQuery() {
    return values.map(
          (key, value) => MapEntry(key, value.toString()),
    );
  }
}

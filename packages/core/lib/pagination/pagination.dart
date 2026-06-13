class Pagination {
  final int page;
  final int limit;

  const Pagination({
    required this.page,
    required this.limit,
  });

  Pagination first() {
    return Pagination(page: 1, limit: limit);
  }

  Pagination next() {
    return Pagination(page: page + 1, limit: limit);
  }

  Pagination copyWith({
    int? page,
    int? limit,
  }) {
    return Pagination(
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

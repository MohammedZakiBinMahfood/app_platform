
import '../core.dart';

class Paginated<T> {
  final List<T> items;
  final Pagination pagination;
  final bool hasNext;
  final bool isLoadingMore;
  final AppError? paginationError;

  const Paginated({
    required this.items,
    required this.pagination,
    required this.hasNext,
    this.isLoadingMore = false,
    this.paginationError,
  });

  Paginated<T> copyWith({
    List<T>? items,
    Pagination? pagination,
    bool? hasNext,
    bool? isLoadingMore,
    AppError? paginationError,
  }) {
    return Paginated<T>(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: paginationError,
    );
  }
}



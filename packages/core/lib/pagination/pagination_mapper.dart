import 'pagination.dart';

abstract class PaginationMapper {
  Map<String, dynamic> toQuery(Pagination pagination);
}

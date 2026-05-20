# 📦 App Platform — مواصفات البناء (الجزء 1: Core + Network)

> **التعليمات:** أنشئ مكتبة Flutter monorepo اسمها `app_platform` بأربع packages: `core`, `network`, `state`, `ui`. هذا الملف يحتوي مواصفات `core` و `network`. الجزء الثاني يحتوي `state` و `ui`.

## الهيكل العام

```
app_platform/
└── packages/
    ├── core/       ← Result, AppError, Paginated, QueryFilters, Logger (Dart فقط — بدون Flutter)
    ├── network/    ← HttpApiClient, Interceptors, TokenProvider (يعتمد على core)
    ├── state/      ← BaseNotifier, PaginatedNotifier, ActionMixin, ValidationController (يعتمد على core + Riverpod)
    └── ui/         ← AsyncView, PaginatedListView, ActionBuilder (يعتمد على core + Flutter)
```

**قاعدة ذهبية:** `core` لا يعتمد على Flutter. `network` يعتمد على `core` + `http`. `state` يعتمد على `core` + `flutter_riverpod`. `ui` يعتمد على `core` + `flutter` فقط (لا يعتمد على state أو network).

---

# 📦 Package 1: `app_platform_core`

## pubspec.yaml
```yaml
name: app_platform_core
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
# لا يوجد dependencies — Dart فقط
```

## Barrel file: `lib/core.dart`
```dart
library app_platform_core;

export 'src/result/result.dart';
export 'src/errors/app_error.dart';
export 'src/errors/common_errors.dart';
export 'src/errors/network_errors.dart';
export 'src/pagination/paginated.dart';
export 'src/pagination/pagination.dart';
export 'src/pagination/pagination_mapper.dart';
export 'src/query/query_filters.dart';
export 'src/status/load_status.dart';
export 'src/network/json_parser.dart';
export 'src/logger/app_logger.dart';
```

---

### 1. `Result<T>` — `src/result/result.dart`

```dart
import '../errors/app_error.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull;
  AppError? get errorOrNull;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  });

  Result<R> map<R>(R Function(T data) transform);
  // إذا Success → يطبق transform ويرجع Success<R>
  // إذا Failure → يرجع Failure<R> بنفس الخطأ

  Result<R> flatMap<R>(Result<R> Function(T data) transform);
  // مثل map لكن الـ transform يرجع Result<R> مباشرة

  T getOrElse(T defaultValue);
  // إذا Success → يرجع data
  // إذا Failure → يرجع defaultValue

  Result<T> onSuccess(void Function(T data) action);
  // ينفذ action إذا Success ويرجع نفس الـ Result (للتسلسل)

  Result<T> onFailure(void Function(AppError error) action);
  // ينفذ action إذا Failure ويرجع نفس الـ Result (للتسلسل)
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  // ... implement all abstract methods
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
  // ... implement all abstract methods
}
```

---

### 2. `AppError` — `src/errors/app_error.dart`

```dart
abstract class AppError {
  final String message;
  final String? code; // اختياري — مفيد للـ i18n

  const AppError(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError && runtimeType == other.runtimeType && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
```

### `src/errors/common_errors.dart`

```dart
class NetworkError extends AppError {
  const NetworkError(super.message);
}

class ServerError extends AppError {
  final int statusCode;
  final String? responseBody;
  const ServerError(this.statusCode, String message, {this.responseBody}) : super(message);
}

class UnknownError extends AppError {
  const UnknownError(super.message);
}
```

### `src/errors/network_errors.dart`

```dart
class NoInternetError extends AppError { const NoInternetError() : super('No internet connection'); }
class TimeoutError extends AppError { const TimeoutError() : super('Request timeout'); }
class UnauthorizedError extends AppError { const UnauthorizedError() : super('Unauthorized'); }
class ForbiddenError extends AppError { const ForbiddenError() : super('Access denied'); }
class NotFoundError extends AppError { const NotFoundError() : super('Resource not found'); }

class ValidationError extends AppError {
  final Map<String, dynamic>? fields;
  const ValidationError(String message, {this.fields}) : super(message);
}
```

---

### 3. `LoadStatus` — `src/status/load_status.dart`

```dart
enum LoadStatus { idle, loading, success, error }
```

---

### 4. `JsonParser` — `src/network/json_parser.dart`

```dart
typedef JsonParser<T> = T Function(dynamic json);
```

---

### 5. `Pagination` — `src/pagination/pagination.dart`

```dart
class Pagination {
  final int page;
  final int limit;
  const Pagination({required this.page, required this.limit});

  Pagination first() => Pagination(page: 1, limit: limit);
  Pagination next() => Pagination(page: page + 1, limit: limit);
  Pagination copyWith({int? page, int? limit});
}
```

### `Paginated<T>` — `src/pagination/paginated.dart`

```dart
class Paginated<T> {
  final List<T> items;
  final Pagination pagination;
  final bool hasNext;
  final bool isLoadingMore;
  final AppError? paginationError;

  const Paginated({...});

  factory Paginated.empty({int limit = 20});

  bool get isEmpty => items.isEmpty;
  int get length => items.length;

  Paginated<T> appendPage(List<T> newItems, {required bool hasMore});
  // يضيف العناصر الجديدة، يحدث pagination.next()، isLoadingMore = false

  Paginated<T> copyWith({...});
  // paginationError يجب أن يقبل null لمسح الخطأ (sentinel pattern)
}
```

### `PaginationMapper` — `src/pagination/pagination_mapper.dart`

```dart
abstract class PaginationMapper {
  Map<String, dynamic> toQuery(Pagination pagination);
}
```

---

### 6. `QueryFilters` — `src/query/query_filters.dart`

```dart
class QueryFilters {
  final Map<String, dynamic> values;
  const QueryFilters([this.values = const {}]);

  bool get isEmpty => values.isEmpty;

  QueryFilters copyWith(Map<String, dynamic> updates);

  // ✅ يتجاهل القيم null
  Map<String, String> toQuery() {
    return Map.fromEntries(
      values.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value.toString())),
    );
  }
}
```

---

### 7. `AppLogger` — `src/logger/app_logger.dart`

```dart
abstract class AppLogger {
  void debug(String message, [Object? error, StackTrace? stack]);
  void info(String message);
  void warning(String message, [Object? error]);
  void error(String message, [Object? error, StackTrace? stack]);
}

class ConsoleLogger implements AppLogger {
  final bool enabled;
  const ConsoleLogger({this.enabled = true});
  // يطبع بـ print مع prefix لكل مستوى: [DEBUG], [INFO], [WARN], [ERROR]
  // إذا enabled = false لا يطبع شيء
}
```

---

# 📦 Package 2: `app_platform_network`

## pubspec.yaml
```yaml
name: app_platform_network
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  http: ">=0.13.0 <2.0.0"
  app_platform_core:
    path: ../core
```

## Barrel file: `lib/network.dart`
```dart
library app_platform_network;

export 'src/client/api_client.dart';
export 'src/client/http_api_client.dart';
export 'src/token/token_provider.dart';
export 'src/interceptors/interceptor.dart';
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/refresh_token_interceptor.dart';
export 'src/interceptors/log_interceptor.dart';
export 'src/interceptors/retry_interceptor.dart';
```

---

### 1. `TokenProvider` — `src/token/token_provider.dart`

```dart
abstract class TokenProvider {
  Future<String?> getToken();
}
```

---

### 2. `Interceptor` — `src/interceptors/interceptor.dart`

```dart
class RequestContext {
  final Uri uri;
  final String method; // GET, POST, etc.
  final Map<String, String> headers;
  final dynamic body;

  RequestContext({required this.uri, required this.method, required this.headers, this.body});
  RequestContext copyWith({Map<String, String>? headers});
}

abstract class AppInterceptor {
  /// يُستدعى قبل إرسال الطلب — يمكنه تعديل الـ headers أو الـ uri
  Future<RequestContext> onRequest(RequestContext context) async => context;

  /// يُستدعى بعد استلام الـ response
  Future<http.Response> onResponse(http.Response response, RequestContext context) async => response;

  /// يُستدعى عند حدوث خطأ
  Future<Result<T>?> onError<T>(AppError error, RequestContext context) async => null;
  // إذا رجع null → الخطأ يمر كما هو
  // إذا رجع Result → يستبدل الخطأ بهذه النتيجة (مفيد لـ retry/refresh)
}
```

---

### 3. `AuthInterceptor` — `src/interceptors/auth_interceptor.dart`

```dart
class AuthInterceptor extends AppInterceptor {
  final TokenProvider tokenProvider;
  AuthInterceptor(this.tokenProvider);

  @override
  Future<RequestContext> onRequest(RequestContext context) async {
    final token = await tokenProvider.getToken();
    if (token != null) {
      return context.copyWith(headers: {...context.headers, 'Authorization': 'Bearer $token'});
    }
    return context;
  }
}
```

---

### 4. `RefreshTokenInterceptor` — `src/interceptors/refresh_token_interceptor.dart`

```dart
class RefreshTokenInterceptor extends AppInterceptor {
  final Future<String?> Function() onRefresh; // يجدد التوكن ويرجع الجديد
  final Future<void> Function() onExpired;     // يُستدعى إذا فشل التجديد (logout)
  bool _isRefreshing = false;

  RefreshTokenInterceptor({required this.onRefresh, required this.onExpired});

  // السلوك: عند 401 → يحاول refresh مرة واحدة → إذا نجح يعيد الطلب → إذا فشل يستدعي onExpired
}
```

---

### 5. `LogInterceptor` — `src/interceptors/log_interceptor.dart`

```dart
class LogInterceptor extends AppInterceptor {
  final AppLogger? logger; // إذا null يستخدم print
  LogInterceptor({this.logger});
  // يطبع: [HTTP] GET https://... → 200 (150ms)
}
```

---

### 6. `RetryInterceptor` — `src/interceptors/retry_interceptor.dart`

```dart
class RetryInterceptor extends AppInterceptor {
  final int maxRetries;
  final Duration delay;
  RetryInterceptor({this.maxRetries = 2, this.delay = const Duration(seconds: 1)});
  // يعيد المحاولة على 500+ وTimeoutError فقط
}
```

---

### 7. `ApiClient` — `src/client/api_client.dart`

```dart
abstract class ApiClient {
  Future<Result<T>> get<T>(String path, {Map<String, dynamic>? query, Map<String, String>? headers, required JsonParser<T> parser});
  Future<Result<T>> post<T>(String path, {Map<String, dynamic>? body, Map<String, dynamic>? query, Map<String, String>? headers, required JsonParser<T> parser});
  Future<Result<T>> put<T>(String path, {Map<String, dynamic>? body, Map<String, String>? headers, required JsonParser<T> parser});
  Future<Result<T>> patch<T>(String path, {Map<String, dynamic>? body, Map<String, String>? headers, required JsonParser<T> parser});
  Future<Result<T>> delete<T>(String path, {Map<String, String>? headers, required JsonParser<T> parser});

  // ✅ جديد: delete بدون parser (للحالات التي لا ترجع response)
  Future<Result<void>> deleteVoid(String path, {Map<String, String>? headers});

  // ✅ جديد: GET لقائمة مع parser تلقائي لعنصر واحد
  Future<Result<List<T>>> getList<T>(String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required JsonParser<T> parser,
    String? listKey, // المفتاح في الـ JSON (مثل "data", "users") — إذا null يفترض الـ root هو List
  });
}
```

---

### 8. `HttpApiClient` — `src/client/http_api_client.dart`

```dart
class HttpApiClient implements ApiClient {
  final String baseUrl;
  final http.Client client;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final List<AppInterceptor> interceptors;
  final ResponseHandler? customHandler;

  HttpApiClient({
    required this.baseUrl,
    required this.client,
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const {},
    this.interceptors = const [],
    this.customHandler,
  });

  // الـ _request method الداخلي:
  // 1. ينشئ RequestContext
  // 2. يمرره على كل interceptor.onRequest بالترتيب
  // 3. يرسل الطلب HTTP
  // 4. يمرر الـ response على كل interceptor.onResponse بالترتيب العكسي
  // 5. إذا خطأ → يمرره على كل interceptor.onError
  // 6. يستخدم customHandler أو _handleResponse الافتراضي

  // _handleResponse:
  // 200-299 → Success(parser(decoded))
  // 401 → Failure(UnauthorizedError())
  // 403 → Failure(ForbiddenError())
  // 404 → Failure(NotFoundError())
  // 422 → Failure(ValidationError(body, fields: decoded['errors']))
  // else → Failure(ServerError(statusCode, body))

  // Exceptions:
  // SocketException → Failure(NoInternetError())
  // TimeoutException → Failure(TimeoutError())
  // else → Failure(UnknownError(e.toString()))
}
```

---

> **يتبع في الجزء 2:** `state` و `ui` packages

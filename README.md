# 📦 App Platform

> Monorepo Flutter يوحّد طريقة بناء الـ features — Result pattern, BaseNotifier, ActionStore, ValidationController.

```
app_platform/
└── packages/
    ├── core/         ← Result<T>, AppError, Paginated<T>, LoadStatus
    ├── network/      ← HttpApiClient, TokenProvider
    ├── state/        ← BaseNotifier, ActionStore, ValidationController
    └── ui/           ← AsyncView, AppTextField
```

---

## 🚀 البدء السريع

### الإضافة إلى المشروع

```yaml
dependencies:
  app_platform_core:
    git:
      url: https://github.com/hassanMohammedDEV/app_platform.git
      ref: <commit-hash>
      path: packages/core
  app_platform_network:
    git:
      url: https://github.com/hassanMohammedDEV/app_platform.git
      ref: <commit-hash>
      path: packages/network
  app_platform_state:
    git:
      url: https://github.com/hassanMohammedDEV/app_platform.git
      ref: <commit-hash>
      path: packages/state
  app_platform_ui:
    git:
      url: https://github.com/hassanMohammedDEV/app_platform.git
      ref: <commit-hash>
      path: packages/ui
```

> [!IMPORTANT]
> جميع الـ packages تشترك بنفس الـ `ref` (commit hash) لأنها تشارك types من `core`.

### تهيئة ApiClient

```dart
// core/providers/api_client_provider.dart
final apiClientProvider = Provider<ApiClient>((ref) {
  return HttpApiClient(
    baseUrl: 'https://your-api.com',
    client: http.Client(),
    tokenProvider: ref.read(tokenProvider),
  );
});

// core/providers/token_provider.dart
class ShipTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() async => 'your-token';
}
```

---

## 📐 قالب بناء Feature

هيكل المجلدات لكل feature:

```
lib/features/{feature_name}/
├── models/
│   └── {model}.dart              ← @MappableClass
├── repositories/
│   ├── {feature}_repository.dart        ← abstract interface
│   └── {feature}_repository_impl.dart   ← implements via ApiClient
├── providers/
│   ├── list_{feature}_notifier.dart     ← BaseNotifier<List<T>>
│   ├── {feature}_crud_notifier.dart     ← StateNotifier<ActionStore>
│   └── {feature}_validation_notifier.dart ← ValidationController
└── presentaion/
    ├── screens/
    └── widgets/
```

---

## 1️⃣ Model

```dart
@MappableClass(caseStyle: CaseStyle.snakeCase)
class Parcel with ParcelMappable {
  final int id;
  final String trackingNumber;
  final String receiverName;
  final String? receiverPhone;
  final double? amount;

  const Parcel({
    required this.id,
    required this.trackingNumber,
    required this.receiverName,
    this.receiverPhone,
    this.amount,
  });
}
```

---

## 2️⃣ Repository

```dart
// ── abstract interface (اختياري لكن مفيد) ──
abstract class ParcelsRepository {
  Future<Result<List<Parcel>>> fetchAll();
  Future<Result<Parcel>> create(Map<String, dynamic> body);
  Future<Result<Parcel>> update(int id, Map<String, dynamic> body);
  Future<Result<void>> delete(int id);
}

// ── implementation ──
class ParcelsRepositoryImpl implements ParcelsRepository {
  final ApiClient _api;
  ParcelsRepositoryImpl(this._api);

  @override
  Future<Result<List<Parcel>>> fetchAll() {
    return _api.post<List<Parcel>>(
      '/rpc/get_all_parcels',
      parser: (json) => parseList<Parcel>(json, ParcelMapper.fromMap),
    );
  }

  @override
  Future<Result<Parcel>> create(Map<String, dynamic> body) {
    return _api.post<Parcel>(
      '/rpc/create_parcel',
      body: body,
      parser: (json) => parseSingle<Parcel>(json, ParcelMapper.fromMap),
    );
  }

  @override
  Future<Result<Parcel>> update(int id, Map<String, dynamic> body) {
    return _api.post<Parcel>(
      '/rpc/update_parcel',
      body: {'id': id, ...body},
      parser: (json) => parseSingle<Parcel>(json, ParcelMapper.fromMap),
    );
  }

  @override
  Future<Result<void>> delete(int id) {
    return _api.post<void>(
      '/rpc/delete_parcel',
      body: {'id': id},
      parser: (_) {},
    );
  }
}
```

### مساعدات RPC Response

```dart
// عند السيرفر يرجع {code, message, data}
typedef JsonParser<T> = T Function(dynamic json);

T parseSingle<T>(dynamic json, T Function(Map<String, dynamic>) fromMap) {
  return fromMap(json['data'] as Map<String, dynamic>);
}

List<T> parseList<T>(dynamic json, T Function(Map<String, dynamic>) fromMap) {
  return (json['data'] as List)
      .map((e) => fromMap(e as Map<String, dynamic>))
      .toList();
}
```

---

## 3️⃣ Notifier (قائمة)

```dart
class ListParcelsNotifier extends BaseNotifier<List<Parcel>> {
  @override
  BaseState<List<Parcel>> build() => BaseState();

  Future<void> load() async {
    setLoading();
    final repo = ref.read(parcelsRepositoryProvider);
    final result = await repo.fetchAll();
    switch (result) {
      case Success(:final data):  setSuccess(data);
      case Failure(:final error): setError(error);
    }
  }
}
```

### الـ Provider

```dart
final parcelsRepositoryProvider = Provider<ParcelsRepository>((ref) {
  return ParcelsRepositoryImpl(ref.read(apiClientProvider));
});

final listParcelsNotifierProvider =
    NotifierProvider<ListParcelsNotifier, BaseState<List<Parcel>>>(
  ListParcelsNotifier.new,
);
```

---

## 4️⃣ CRUD Actions

للعمليات المنفردة (حذف، إنشاء، تعديل) نستخدم `ActionStore` بدل `BaseNotifier`:

```dart
class ParcelCrudNotifier extends StateNotifier<ActionStore> {
  ParcelCrudNotifier(this._ref) : super(ActionStore());
  final Ref _ref;

  Future<void> delete(int id) async {
    state = state.start('delete_$id');
    final repo = _ref.read(parcelsRepositoryProvider);
    final result = await repo.delete(id);
    switch (result) {
      case Success():
        state = state.success('delete_$id');
        _ref.invalidate(listParcelsNotifierProvider);
      case Failure(:final error):
        state = state.fail('delete_$id', error);
    }
  }
}

final parcelCrudNotifierProvider =
    StateNotifierProvider<ParcelCrudNotifier, ActionStore>((ref) {
  return ParcelCrudNotifier(ref);
});
```

---

## 5️⃣ Validation (فورم)

```dart
enum ParcelsFields { receiverName, receiverPhone, amount }

class ParcelsValidationNotifier
    extends ValidationController<ParcelsFields> {
  @override
  FormValidationState<ParcelsFields> build() {
    init(
      validators: {
        ParcelsFields.receiverName: (ctx) {
          final v = ctx.value as String? ?? '';
          if (v.isEmpty) return 'اسم المستلم مطلوب';
          return null;
        },
        ParcelsFields.amount: (ctx) {
          final v = ctx.value as String? ?? '';
          if (v.isEmpty) return null; // اختياري
          if (double.tryParse(v) == null) return 'يجب أن يكون رقماً';
          return null;
        },
      },
    );
    return FormValidationState();
  }

  @override
  dynamic getFieldValue(ParcelsFields field) {
    // يرجع القيمة من StateProvider أو TextEditingController
  }
}
```

---

## 6️⃣ UI — AsyncView

```dart
AsyncView<List<Parcel>>(
  status: state.status,
  data: state.data,
  error: state.error,
  onLoading: () => const LoadingView(),
  onError: (error) => ErrorView(error: error),
  onEmpty: () => const Center(child: Text('لا توجد شحنات')),
  onSuccess: (parcels) => ListView.builder(
    itemCount: parcels.length,
    itemBuilder: (_, i) => Text(parcels[i].receiverName),
  ),
)
```

### استخدام BaseState.when

```dart
state.when(
  loading: () => const LoadingView(),
  error: (e) => ErrorView(error: e),
  success: (data) => Text(data.length.toString()),
);
```

---

## 📊 مرجع API

### Core

| الكلاس | الوصف |
|---|---|
| `Result<T>` — `Success(data)` / `Failure(error)` | نتيجة عملية غير متزامنة |
| `BaseState<T>` — `.status`, `.data`, `.error` | حالة الشاشة (idle → loading → success/error) |
| `AppError` | خطأ مع `message` |
| `NetworkError`, `ServerError`, `UnknownError` | أخطاء شائعة |
| `NoInternetError`, `TimeoutError`, `UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ValidationError` | أخطاء الشبكة |
| `LoadStatus` — `{ idle, loading, success, error }` | حالات التحميل |
| `Paginated<T>` — `items`, `hasNext`, `isLoadingMore` | نموذج التصفح |
| `QueryFilters` — `toQuery()` | فلاتر البحث |
| `JsonParser<T>` | دالة تحليل JSON |

### Network

| الكلاس | الوصف |
|---|---|
| `ApiClient` — `get`, `post`, `put`, `patch`, `delete` | واجهة API |
| `HttpApiClient implements ApiClient` | تنفيذ HTTP مع Token injection |
| `TokenProvider` — `getToken()` | مصدر التوكن |

### State

| الكلاس | الوصف |
|---|---|
| `BaseNotifier<T>` — `setLoading()`, `setSuccess()`, `setError()`, `fetch()` | أساس الـ Notifier |
| `BaseStateWhen<T>` — `when()` | بناء Widget حسب الحالة |
| `ActionStore` — `start()`, `success()`, `fail()`, `clear()`, `get()` | تتبع العمليات |
| `ActionState` — `isLoading`, `isSuccess`, `isFailure` | حالة عملية واحدة |
| `ActionKey(type, [id])` | مفتاح فريد لعملية |
| `ActionType` — `create`, `update`, `delete`, ... | أنواع العمليات |
| `ActionMixin` — `runAction()`, `actions` | Mixin للإجراءات |
| `listenForActions()` | رصد اكتمال العمليات |
| `ValidationController<K>` — `init()`, `validate()`, `validateAsync()`, `validateAll()` | التحقق من الفورم |
| `Validators` — `required()`, `email()`, `numeric()`, `minLength()`, ... | دوال تحقق جاهزة |
| `PaginatedNotifier<T>` — `load()`, `loadMore()`, `refresh()`, `applyFilters()` | تصفح مع تحميل تدريجي |

### UI

| الـ Widget | الوصف |
|---|---|
| `AsyncView<T>` | يعرض loading/error/empty/success حسب `LoadStatus` |
| `LoadingView` | CircularProgressIndicator |
| `ErrorView` | عرض رسالة الخطأ |
| `AppTextField` | TextField مع errorText, loading indicator |

---

## ✅ الـ Checklist

- [ ] Model مع `@MappableClass` و `fromJson`/`toJson`
- [ ] Repository يرجع `Result<T>` في كل الدوال
- [ ] `BaseNotifier` للقوائم — `fetch(task)` يختصر الـ pattern
- [ ] `ActionStore` للـ CRUD — `start/success/fail`
- [ ] `ref.invalidate()` لتحديث القائمة بعد CRUD
- [ ] `ValidationController` مع `init()` و `validators`
- [ ] `validateBeforeSubmit()` — `validateAll()` قبل الإرسال
- [ ] `AsyncView` في الشاشات
- [ ] `listenForActions` للـ SnackBars والتنقل

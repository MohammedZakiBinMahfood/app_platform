# 📦 App Platform — مواصفات البناء (الجزء 2: State + UI)

> **تكملة الجزء 1.** هذا الملف يحتوي مواصفات `state` و `ui`.

---

# 📦 Package 3: `app_platform_state`

## pubspec.yaml
```yaml
name: app_platform_state
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.0.0
  app_platform_core:
    path: ../core
```

## Barrel file: `lib/state.dart`
```dart
library app_platform_state;

export 'src/base/base_state.dart';
export 'src/base/base_notifier.dart';
export 'src/base/paginated_notifier.dart';
export 'src/action/action_state.dart';
export 'src/action/action_status.dart';
export 'src/action/action_store.dart';
export 'src/action/action_mixin.dart';
export 'src/action/action_key.dart';
export 'src/action/action_type.dart';
export 'src/action/action_listener.dart';
export 'src/models/reaction_model.dart';
export 'src/form/validation_field_state.dart';
export 'src/form/form_validation_state.dart';
export 'src/form/validation_context.dart';
export 'src/form/validation_controller.dart';
export 'src/form/validator_type.dart';
export 'src/form/validators.dart';
export 'src/extensions/result_extensions.dart';
```

---

## Base State

### `BaseState<T>` — `src/base/base_state.dart`

```dart
class BaseState<T> {
  final LoadStatus status;
  final T? data;
  final AppError? error;

  const BaseState({
    this.status = LoadStatus.idle,
    this.data,
    this.error,
  });

  // ✅ استخدم sentinel pattern لمسح القيم
  BaseState<T> copyWith({
    LoadStatus? status,
    Object? data = _unset,    // مرر null صراحة لمسح الـ data
    Object? error = _unset,   // مرر null صراحة لمسح الـ error
  });
}
```

### `BaseNotifier<T>` — `src/base/base_notifier.dart`

```dart
// ✅ يستخدم Notifier (ليس StateNotifier المهمل)
abstract class BaseNotifier<T> extends Notifier<BaseState<T>> {
  @override
  BaseState<T> build() => const BaseState();

  void setLoading() => state = state.copyWith(status: LoadStatus.loading, error: null);
  void setSuccess(T data) => state = BaseState(status: LoadStatus.success, data: data);
  void setError(AppError error) => state = BaseState(status: LoadStatus.error, error: error);

  /// ✅ الأهم — يختصر pattern الـ loading → API → success/error
  Future<void> fetch(Future<Result<T>> Function() task) async {
    setLoading();
    final result = await task();
    switch (result) {
      case Success(:final data): setSuccess(data);
      case Failure(:final error): setError(error);
    }
  }

  /// helper: تحديث الـ data مباشرة (بدون loading)
  void updateData(T Function(T current) updater) {
    if (state.data != null) {
      state = state.copyWith(data: updater(state.data as T));
    }
  }
}
```

### `PaginatedNotifier<T>` — `src/base/paginated_notifier.dart`

```dart
abstract class PaginatedNotifier<T> extends Notifier<BaseState<Paginated<T>>> {
  int get limit => 20;

  @override
  BaseState<Paginated<T>> build() => const BaseState();

  /// يجب أن ينفذها المستخدم
  Future<Result<List<T>>> fetchPage(int page, int limit, {QueryFilters? filters});

  QueryFilters _currentFilters = const QueryFilters();

  /// تحميل أول صفحة
  Future<void> load() async {
    state = state.copyWith(status: LoadStatus.loading);
    final result = await fetchPage(1, limit, filters: _currentFilters);
    switch (result) {
      case Success(:final data):
        state = BaseState(
          status: LoadStatus.success,
          data: Paginated(
            items: data,
            pagination: Pagination(page: 1, limit: limit),
            hasNext: data.length >= limit,
          ),
        );
      case Failure(:final error):
        state = BaseState(status: LoadStatus.error, error: error);
    }
  }

  /// تحميل الصفحة التالية
  Future<void> loadMore() async {
    final current = state.data;
    if (current == null || !current.hasNext || current.isLoadingMore) return;

    state = state.copyWith(data: current.copyWith(isLoadingMore: true));

    final nextPage = current.pagination.next();
    final result = await fetchPage(nextPage.page, nextPage.limit, filters: _currentFilters);

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          data: current.appendPage(data, hasMore: data.length >= limit),
        );
      case Failure(:final error):
        state = state.copyWith(
          data: current.copyWith(isLoadingMore: false, paginationError: error),
        );
    }
  }

  /// إعادة تحميل من البداية
  Future<void> refresh() => load();

  /// تطبيق فلاتر (يعيد التحميل من الصفحة الأولى)
  Future<void> applyFilters(QueryFilters filters) {
    _currentFilters = filters;
    return load();
  }

  // ✅ helpers لتحديث القائمة بدون إعادة تحميل
  void removeWhere(bool Function(T item) test) {
    if (state.data != null) {
      state = state.copyWith(
        data: state.data!.copyWith(
          items: state.data!.items.where((i) => !test(i)).toList(),
        ),
      );
    }
  }

  void updateWhere(bool Function(T item) test, T Function(T item) updater) {
    if (state.data != null) {
      state = state.copyWith(
        data: state.data!.copyWith(
          items: state.data!.items.map((i) => test(i) ? updater(i) : i).toList(),
        ),
      );
    }
  }

  void addItem(T item, {bool prepend = true}) {
    if (state.data != null) {
      final items = prepend
          ? [item, ...state.data!.items]
          : [...state.data!.items, item];
      state = state.copyWith(data: state.data!.copyWith(items: items));
    }
  }
}
```

---

## Action System

### `ActionStatus` — `src/action/action_status.dart`

```dart
enum ActionStatus { idle, loading, success, failure }
```

### `ActionState` — `src/action/action_state.dart`

```dart
class ActionState {
  final ActionStatus status;
  final AppError? error;

  const ActionState._({required this.status, this.error});

  const ActionState.idle() : this._(status: ActionStatus.idle);
  const ActionState.loading() : this._(status: ActionStatus.loading);
  const ActionState.success() : this._(status: ActionStatus.success);
  const ActionState.failure(AppError error) : this._(status: ActionStatus.failure, error: error);

  bool get isLoading => status == ActionStatus.loading;
  bool get isSuccess => status == ActionStatus.success;
  bool get isFailure => status == ActionStatus.failure;
  bool get isIdle => status == ActionStatus.idle;
}
```

### `ActionType` — `src/action/action_type.dart`

```dart
enum ActionType {
  create, update, delete,
  check, validate,
  submit, save,
  activate, deactivate,
  archive, restore,
  login, logout,
  upload,
}
```

### `ActionKey` — `src/action/action_key.dart`

```dart
class ActionKey {
  final ActionType type;
  final String? id;
  const ActionKey(this.type, {this.id});

  String get value => id == null ? type.name : '${type.name}_$id';

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is ActionKey && type == other.type && id == other.id;

  @override
  int get hashCode => Object.hash(type, id);
}
```

### `ActionStore` — `src/action/action_store.dart` (Immutable)

```dart
class ActionStore {
  final Map<String, ActionState> _actions;
  ActionStore([Map<String, ActionState>? actions]) : _actions = actions ?? const {};

  ActionState get(String key) => _actions[key] ?? const ActionState.idle();
  bool isLoading(String key) => get(key).isLoading;
  bool isSuccess(String key) => get(key).isSuccess;
  bool isFailure(String key) => get(key).isFailure;

  ActionStore start(String key) => ActionStore({..._actions, key: const ActionState.loading()});
  ActionStore success(String key) => ActionStore({..._actions, key: const ActionState.success()});
  ActionStore fail(String key, AppError error) => ActionStore({..._actions, key: ActionState.failure(error)});
  ActionStore clear(String key) => ActionStore(Map.from(_actions)..remove(key));
}
```

### `ActionMixin` — `src/action/action_mixin.dart`

```dart
/// ✅ يعمل مع أي Notifier يحتوي BaseState
mixin ActionMixin<T> on BaseNotifier<T> {
  ActionStore _actions = ActionStore();
  ActionStore get actions => _actions;

  void _updateActions(ActionStore newActions) {
    _actions = newActions;
    // نعيد بناء الـ state لإخبار الـ UI (trigger rebuild)
    state = state.copyWith();
  }

  /// ✅ الـ method الرئيسي — يختصر الـ action lifecycle كامل
  Future<void> runAction<R>({
    required ActionKey key,
    required Future<Result<R>> Function() task,
    void Function(R data)? onSuccess,
    void Function(AppError error)? onError,
  }) async {
    _updateActions(_actions.start(key.value));

    final result = await task();

    switch (result) {
      case Success(:final data):
        _updateActions(_actions.success(key.value));
        onSuccess?.call(data);
      case Failure(:final error):
        _updateActions(_actions.fail(key.value, error));
        onError?.call(error);
    }
  }

  void clearAction(ActionKey key) => _updateActions(_actions.clear(key.value));
}
```

> **ملاحظة:** PaginatedNotifier يدعم ActionMixin أيضاً بنفس الطريقة.

### `ActionReaction` — `src/models/reaction_model.dart`

```dart
class ActionReaction {
  final VoidCallback onSuccess;
  final void Function(AppError error) onError;
  const ActionReaction({required this.onSuccess, required this.onError});
}
```

### `listenForActions` — `src/action/action_listener.dart`

```dart
void listenForActions({
  required WidgetRef ref,
  required ProviderListenable<ActionStore> provider,
  required Map<ActionKey, ActionReaction> reactions,
}) {
  ref.listen<ActionStore>(provider, (previous, next) {
    if (previous == null) return;
    for (final entry in reactions.entries) {
      final key = entry.key.value;
      final prevAction = previous.get(key);
      final nextAction = next.get(key);

      // ✅ فحص صحيح
      if (prevAction.isLoading && nextAction.isSuccess) {
        entry.value.onSuccess();
      }
      if (prevAction.isLoading && nextAction.isFailure) {
        entry.value.onError(nextAction.error!);
      }
    }
  });
}
```

---

## Result Extensions — `src/extensions/result_extensions.dart`

```dart
extension ResultToBaseState<T> on Result<T> {
  BaseState<T> toBaseState() => switch (this) {
    Success(:final data) => BaseState(status: LoadStatus.success, data: data),
    Failure(:final error) => BaseState(status: LoadStatus.error, error: error),
  };
}
```

---

## Validation System

### `ValidationFieldState` — `src/form/validation_field_state.dart`

```dart
class ValidationFieldState {
  final String? error;
  final bool touched;
  final bool validating;

  const ValidationFieldState({this.error, this.touched = false, this.validating = false});

  bool get isValid => error == null;
  bool get showError => touched && error != null; // ✅ أظهر الخطأ فقط بعد اللمس

  // sentinel pattern لمسح الـ error
  ValidationFieldState copyWith({Object? error = _unset, bool? touched, bool? validating});
}
const _unset = Object();
```

### `FormValidationState<K>` — `src/form/form_validation_state.dart`

```dart
class FormValidationState<K extends Enum> {
  final Map<K, ValidationFieldState> fields;
  const FormValidationState({this.fields = const {}});

  ValidationFieldState field(K key) => fields[key] ?? const ValidationFieldState();

  FormValidationState<K> updateField(K key, ValidationFieldState field);

  bool get isValid => fields.values.every((e) => e.isValid);
  bool get isValidating => fields.values.any((e) => e.validating);
  bool get canSubmit => isValid && !isValidating;
}
```

### `ValidationContext<K>` — `src/form/validation_context.dart`

```dart
class ValidationContext<K extends Enum> {
  final Ref ref;
  final K field;
  final dynamic value; // ✅ قيمة الحقل الحالية — يجب أن يمررها الـ controller

  const ValidationContext({required this.ref, required this.field, required this.value});

  T read<T>(ProviderListenable<T> provider) => ref.read(provider);
}
```

### Validator Types — `src/form/validator_type.dart`

```dart
typedef Validator<K extends Enum> = String? Function(ValidationContext<K> context);
typedef AsyncValidator<K extends Enum> = Future<String?> Function(ValidationContext<K> context);
typedef FieldValidator = String? Function(dynamic value);
```

### `ValidationController<K>` — `src/form/validation_controller.dart`

```dart
abstract class ValidationController<K extends Enum> extends Notifier<FormValidationState<K>> {
  late final Map<K, Validator<K>> _validators;
  late final Map<K, AsyncValidator<K>> _asyncValidators;
  final Map<K, Timer?> _debounceTimers = {}; // ✅ timer لكل حقل مستقل

  @override
  FormValidationState<K> build();

  void init({
    Map<K, Validator<K>> validators = const {},
    Map<K, AsyncValidator<K>> asyncValidators = const {},
  }) {
    _validators = validators;
    _asyncValidators = asyncValidators;
    ref.onDispose(() {
      for (final timer in _debounceTimers.values) { timer?.cancel(); }
    });
    state = FormValidationState<K>();
  }

  // ✅ المستخدم يجب أن ينفذ هذه — يرجع القيمة الحالية للحقل
  // (من TextEditingController أو StateProvider أو أي مصدر)
  dynamic getFieldValue(K field);

  void validate(K field) {
    final validator = _validators[field];
    final error = validator?.call(ValidationContext(ref: ref, field: field, value: getFieldValue(field)));
    state = state.updateField(field, state.field(field).copyWith(error: error, touched: true));
  }

  Future<void> validateAsync(K field) async {
    validate(field);

    final asyncValidator = _asyncValidators[field];
    if (asyncValidator == null) return;

    _debounceTimers[field]?.cancel(); // ✅ يلغي timer هذا الحقل فقط

    _debounceTimers[field] = Timer(const Duration(milliseconds: 400), () async {
      state = state.updateField(field, state.field(field).copyWith(validating: true));

      final error = await asyncValidator(ValidationContext(ref: ref, field: field, value: getFieldValue(field)));

      state = state.updateField(field, state.field(field).copyWith(error: error, validating: false));
    });
  }

  void touch(K field) { ... }
  void clear(K field) { state = state.updateField(field, state.field(field).copyWith(error: null)); }

  bool validateAll() { /* يتحقق من كل الحقول، يرجع true/false */ }
  bool validateStep(List<K> fields) { /* يتحقق من حقول محددة فقط */ }
  void reset() { state = FormValidationState<K>(); }

  void setFieldValidation(K field, {String? error, bool touched = true}) { /* لأخطاء السيرفر */ }
}
```

### `Validators` — `src/form/validators.dart`

```dart
class Validators {
  static FieldValidator required({String message = 'حقل مطلوب'});
  static FieldValidator email({String message = 'بريد غير صحيح'});
  static FieldValidator minLength(int length, {String? message});
  static FieldValidator maxLength(int length, {String? message});
  static FieldValidator numeric({String message = 'يجب أن يكون رقم'});
  static FieldValidator range({required num min, required num max, String? message});
  static FieldValidator website({String message = 'رابط غير صحيح'});
  static FieldValidator pattern(RegExp regex, {required String message});
  static FieldValidator combine(List<FieldValidator> validators);
  // combine: ينفذ الكل بالترتيب ويتوقف عند أول خطأ
}
```

---

# 📦 Package 4: `app_platform_ui`

## pubspec.yaml
```yaml
name: app_platform_ui
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  app_platform_core:
    path: ../core
```

**لا يعتمد على state أو network — widgets بحتة.**

## Barrel file: `lib/ui.dart`
```dart
library app_platform_ui;

export 'src/async/async_view.dart';
export 'src/pagination/paginated_list_view.dart';
export 'src/action/action_builder.dart';
```

---

### `AsyncView<T>` — `src/async/async_view.dart`

```dart
class AsyncView<T> extends StatelessWidget {
  final LoadStatus status;
  final T? data;
  final AppError? error;

  final Widget Function() onLoading;
  final Widget Function(AppError error) onError;
  final Widget Function() onEmpty;
  final Widget Function(T data) onSuccess;
  final Widget Function()? onIdle;  // ✅ جديد
  final bool animate; // ✅ AnimatedSwitcher — default: false

  // build:
  // idle → onIdle ?? SizedBox.shrink
  // loading → onLoading
  // error → onError(error ?? UnknownError)
  // success → data == null ? onEmpty : onSuccess(data!)
  // إذا animate = true → يلف النتيجة بـ AnimatedSwitcher(duration: 300ms)
}
```

### `PaginatedListView<T>` — `src/pagination/paginated_list_view.dart`

```dart
class PaginatedListView<T> extends StatelessWidget {
  final BaseState<Paginated<T>> state;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget Function()? loadingBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function(AppError error)? errorBuilder;
  final Widget Function()? loadMoreBuilder;
  final Widget Function(AppError error)? loadMoreErrorBuilder;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;

  // build:
  // 1. يستخدم AsyncView لعرض loading/error/empty
  // 2. في حالة success → RefreshIndicator wrapping ListView.builder
  // 3. آخر item: إذا isLoadingMore → loadMoreBuilder
  //              إذا paginationError → loadMoreErrorBuilder
  //              إذا hasNext → يستدعي onLoadMore تلقائياً (scroll listener)
}
```

### `ActionBuilder` — `src/action/action_builder.dart`

```dart
/// يقرأ حالة action محدد من ActionStore ويبني الـ widget بناءً عليها
class ActionBuilder extends StatelessWidget {
  final ActionStore store;
  final ActionKey actionKey;
  final Widget Function(BuildContext context, ActionState state) builder;

  // build:
  // يقرأ store.get(actionKey.value) ويمررها لـ builder
}
```

---

# 📋 ملاحظات التنفيذ

1. **كل copyWith يستخدم sentinel pattern** (`_unset`) لدعم تمرير `null` صراحة لمسح القيم
2. **كل class يحتاج `==` و `hashCode`:** `ActionKey`, `ActionState`, `ActionStore`, `BaseState`, `Paginated`, `Pagination`, `ValidationFieldState`, `FormValidationState`
3. **لا يوجد أي widget خاص بـ TextField أو أي input** — الـ validation منطق صافي فقط
4. **`BaseNotifier` يستخدم `Notifier`** (Riverpod 2.x) وليس `StateNotifier`
5. **Debounce في ValidationController لكل حقل بشكل مستقل**
6. **Interceptors تعمل بالترتيب: request (أول→آخر)، response (آخر→أول)**

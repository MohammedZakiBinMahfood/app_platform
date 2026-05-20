# 🚀 Feature Implementation Template — App Platform

> دليل شامل ومرجع كامل لبناء أي feature باستخدام **App Platform**.
> يغطي **كل** شيء: من الـ Model إلى الـ UI، شاملاً الـ Validation والـ Pagination والـ Actions.

---

## 📁 هيكل الملفات المقترح لكل Feature

```
lib/
└── features/
    └── [feature_name]/
        ├── data/
        │   ├── models/
        │   │   └── [feature_name]_model.dart        ← الموديل
        │   └── repositories/
        │       └── [feature_name]_repository.dart    ← API calls
        ├── logic/
        │   ├── [feature_name]_notifier.dart          ← State management
        │   ├── [feature_name]_validation.dart        ← Validation controller
        │   └── [feature_name]_providers.dart         ← Riverpod providers
        └── presentation/
            ├── screens/
            │   ├── [feature_name]_list_screen.dart   ← شاشة القائمة
            │   └── [feature_name]_form_screen.dart   ← شاشة الإنشاء/التعديل
            └── widgets/
                └── [feature_name]_card.dart          ← Widgets مخصصة
```

---

## 1️⃣ Data Layer — الموديل (`Model`)

أنشئ الموديل مع `fromJson` و `toJson`.

```dart
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.isActive,
    required this.createdAt,
  });

  /// ✅ من JSON (للقراءة من API)
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// ✅ إلى JSON (للإرسال إلى API)
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'is_active': isActive,
  };

  /// ✅ copyWith للتحديث المحلي
  Product copyWith({
    String? name,
    String? description,
    double? price,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
```

---

## 2️⃣ Network Layer — المستودع (`Repository`)

كل عمليات الـ API هنا. ترجع `Result<T>` دائماً.

```dart
import 'package:app_platform_network/network.dart';
import 'package:app_platform_core/core.dart';

class ProductRepository {
  final ApiClient _api;
  const ProductRepository(this._api);

  // ───────────────────────────── READ ─────────────────────────────

  /// ✅ جلب عنصر واحد
  Future<Result<Product>> fetchOne(int id) {
    return _api.get<Product>(
      '/products/$id',
      parser: (json) => Product.fromJson(json),
    );
  }

  /// ✅ جلب قائمة (بدون pagination)
  Future<Result<List<Product>>> fetchAll() {
    return _api.get<List<Product>>(
      '/products',
      parser: (json) =>
        (json['data'] as List).map((e) => Product.fromJson(e)).toList(),
    );
  }

  /// ✅ جلب قائمة مع pagination + filters
  Future<Result<List<Product>>> fetchPage({
    required int page,
    required int limit,
    QueryFilters? filters,
  }) {
    return _api.get<List<Product>>(
      '/products',
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (filters != null) ...filters.toQuery(),
      },
      parser: (json) =>
        (json['data'] as List).map((e) => Product.fromJson(e)).toList(),
    );
  }

  // ───────────────────────────── CREATE ─────────────────────────────

  /// ✅ إنشاء عنصر جديد
  Future<Result<Product>> create(Map<String, dynamic> body) {
    return _api.post<Product>(
      '/products',
      body: body,
      parser: (json) => Product.fromJson(json['data']),
    );
  }

  // ───────────────────────────── UPDATE ─────────────────────────────

  /// ✅ تعديل عنصر
  Future<Result<Product>> update(int id, Map<String, dynamic> body) {
    return _api.put<Product>(
      '/products/$id',
      body: body,
      parser: (json) => Product.fromJson(json['data']),
    );
  }

  /// ✅ تعديل جزئي (patch)
  Future<Result<Product>> patch(int id, Map<String, dynamic> body) {
    return _api.patch<Product>(
      '/products/$id',
      body: body,
      parser: (json) => Product.fromJson(json['data']),
    );
  }

  // ───────────────────────────── DELETE ─────────────────────────────

  /// ✅ حذف عنصر (مع response)
  Future<Result<void>> delete(int id) {
    return _api.delete<void>(
      '/products/$id',
      parser: (_) {},
    );
  }

  // ───────────────────────────── CUSTOM ACTIONS ─────────────────────────────

  /// ✅ تفعيل / إلغاء تفعيل
  Future<Result<Product>> toggleActive(int id, bool activate) {
    return _api.patch<Product>(
      '/products/$id/toggle',
      body: {'is_active': activate},
      parser: (json) => Product.fromJson(json['data']),
    );
  }

  /// ✅ رفع ملف
  // ملاحظة: يحتاج تنفيذ multipart خاص
}
```

---

## 3️⃣ State Layer — الـ Notifier

### الخيار أ: `BaseNotifier` — للقوائم البسيطة أو العنصر الواحد

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_platform_core/core.dart';
import 'package:app_platform_state/state.dart';

class ProductNotifier extends BaseNotifier<List<Product>> with ActionMixin<List<Product>> {
  late final ProductRepository _repo;

  @override
  BaseState<List<Product>> build() {
    _repo = ref.read(productRepositoryProvider);
    return BaseState();
  }

  // ───────────────────────────── FETCH ─────────────────────────────

  /// ✅ تحميل البيانات — يستخدم setLoading/setSuccess/setError تلقائياً
  Future<void> load() async {
    setLoading();
    final result = await _repo.fetchAll();
    switch (result) {
      case Success(:final data):
        setSuccess(data);
      case Failure(:final error):
        setError(error);
    }
  }

  // ───────────────────────────── DELETE ─────────────────────────────

  /// ✅ حذف مع ActionMixin — كل عنصر له حالة مستقلة
  Future<void> deleteProduct(int id) async {
    final key = ActionKey(ActionType.delete, id.toString());

    await runAction(
      key: key,
      task: () => _repo.delete(id),
      onSuccess: (_) {
        // 🔄 الخيار 1: إعادة تحميل القائمة كاملة
        load();

        // ⚡ الخيار 2: تحديث محلي (أسرع)
        // updateData((items) => items.where((p) => p.id != id).toList());
      },
      onError: (error) {
        // يمكن إضافة logging أو أي معالجة إضافية
      },
    );
  }

  // ───────────────────────────── CREATE ─────────────────────────────

  /// ✅ إنشاء عنصر جديد
  Future<void> createProduct(Map<String, dynamic> body) async {
    final key = ActionKey(ActionType.create);

    await runAction(
      key: key,
      task: () => _repo.create(body),
      onSuccess: (product) {
        // إضافة العنصر الجديد في بداية القائمة
        updateData((items) => [product, ...items]);
      },
    );
  }

  // ───────────────────────────── UPDATE ─────────────────────────────

  /// ✅ تعديل عنصر
  Future<void> updateProduct(int id, Map<String, dynamic> body) async {
    final key = ActionKey(ActionType.update, id.toString());

    await runAction(
      key: key,
      task: () => _repo.update(id, body),
      onSuccess: (updatedProduct) {
        updateData((items) =>
          items.map((p) => p.id == id ? updatedProduct : p).toList(),
        );
      },
    );
  }

  // ───────────────────────── TOGGLE (activate/deactivate) ──────────────────

  /// ✅ تفعيل / إلغاء تفعيل
  Future<void> toggleActive(int id, bool activate) async {
    final actionType = activate ? ActionType.activate : ActionType.deactivate;
    final key = ActionKey(actionType, id.toString());

    await runAction(
      key: key,
      task: () => _repo.toggleActive(id, activate),
      onSuccess: (updatedProduct) {
        updateData((items) =>
          items.map((p) => p.id == id ? updatedProduct : p).toList(),
        );
      },
    );
  }
}
```

---

### الخيار ب: `PaginatedNotifier` — للقوائم مع Infinite Scroll

```dart
class ProductPaginatedNotifier extends PaginatedNotifier<Product>
    with ActionMixin<Paginated<Product>> {
  late final ProductRepository _repo;

  @override
  int get limit => 20;

  @override
  BaseState<Paginated<Product>> build() {
    _repo = ref.read(productRepositoryProvider);
    return BaseState();
  }

  /// ✅ يجب تنفيذ هذه الدالة — تُستدعى تلقائياً من load() و loadMore()
  @override
  Future<Result<List<Product>>> fetchPage(
    int page,
    int limit, {
    QueryFilters? filters,
  }) {
    return _repo.fetchPage(page: page, limit: limit, filters: filters);
  }

  // ───────────────────────── Delete ──────────────────

  Future<void> deleteProduct(int id) async {
    final key = ActionKey(ActionType.delete, id.toString());

    await runAction(
      key: key,
      task: () => _repo.delete(id),
      onSuccess: (_) {
        // تحديث محلي — إزالة العنصر بدون إعادة تحميل
        removeWhere((p) => p.id == id);
      },
    );
  }

  // ───────────────────────── Update ──────────────────

  Future<void> updateProduct(int id, Map<String, dynamic> body) async {
    final key = ActionKey(ActionType.update, id.toString());

    await runAction(
      key: key,
      task: () => _repo.update(id, body),
      onSuccess: (updated) {
        updateWhere((p) => p.id == id, (_) => updated);
      },
    );
  }

  // ───────────────────────── Create ──────────────────

  Future<void> createProduct(Map<String, dynamic> body) async {
    final key = ActionKey(ActionType.create);

    await runAction(
      key: key,
      task: () => _repo.create(body),
      onSuccess: (product) {
        addItem(product, prepend: true); // يضيف في أعلى القائمة
      },
    );
  }

  // ───────────────────────── Filters ──────────────────

  /// ✅ تطبيق فلاتر (يعيد التحميل من الصفحة الأولى تلقائياً)
  Future<void> filterByCategory(String category) {
    return applyFilters(QueryFilters({'category': category}));
  }
}
```

---

## 4️⃣ Validation Layer — نظام التحقق الكامل

### تعريف حقول الفورم (`enum`)

```dart
/// ✅ كل حقل في الفورم يُمثل بقيمة في الـ enum
enum ProductFields {
  name,
  description,
  price,
  email,
  website,
}
```

### الـ `ValidationController` — المتحكم بالتحقق

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_platform_state/state.dart';

class ProductValidationController extends ValidationController<ProductFields> {

  @override
  FormValidationState<ProductFields> build() {
    // ✅ تهيئة المتحقق مع sync + async validators
    init(
      validators: {

        // ─────────── حقل الاسم: مطلوب + حد أدنى 3 أحرف ─────────────
        ProductFields.name: (context) {
          final value = context.value as String? ?? '';
          return Validators.combine([
            Validators.required(message: 'الاسم مطلوب'),
            Validators.minLength(3, message: 'الاسم يجب أن يكون 3 أحرف على الأقل'),
            Validators.maxLength(100, message: 'الاسم يجب أن لا يتجاوز 100 حرف'),
          ])(value);
        },

        // ─────────── حقل الوصف: اختياري، لكن إذا مُلئ يجب 10 أحرف ─────────────
        ProductFields.description: (context) {
          final value = context.value as String? ?? '';
          if (value.isEmpty) return null; // اختياري
          return Validators.minLength(10,
            message: 'الوصف يجب أن يكون 10 أحرف على الأقل',
          )(value);
        },

        // ─────────── حقل السعر: مطلوب + رقم + نطاق ─────────────
        ProductFields.price: (context) {
          final value = context.value as String? ?? '';
          return Validators.combine([
            Validators.required(message: 'السعر مطلوب'),
            Validators.numeric(message: 'يجب أن يكون رقماً'),
            Validators.range(
              min: 0.01,
              max: 999999,
              message: 'السعر يجب أن يكون بين 0.01 و 999,999',
            ),
          ])(value);
        },

        // ─────────── حقل الإيميل: اختياري + تحقق من الصيغة ─────────────
        ProductFields.email: (context) {
          final value = context.value as String? ?? '';
          if (value.isEmpty) return null;
          return Validators.email(message: 'البريد الإلكتروني غير صحيح')(value);
        },

        // ─────────── حقل الموقع: اختياري + تحقق من الرابط ─────────────
        ProductFields.website: (context) {
          final value = context.value as String? ?? '';
          if (value.isEmpty) return null;
          return Validators.website(message: 'الرابط غير صحيح')(value);
        },
      },

      // ─────────── Async Validators (تحقق من السيرفر) ─────────────
      asyncValidators: {
        ProductFields.name: (context) async {
          final value = context.value as String? ?? '';
          if (value.length < 3) return null; // لا تتحقق إذا القيمة قصيرة

          // ✅ مثال: التحقق من تكرار الاسم في السيرفر
          final repo = context.read(productRepositoryProvider);
          final result = await repo.checkNameExists(value);

          return switch (result) {
            Success(:final data) => data ? 'هذا الاسم مستخدم بالفعل' : null,
            Failure(_) => null, // تجاهل أخطاء الشبكة في التحقق
          };
        },
      },
    );

    return FormValidationState<ProductFields>();
  }
}
```

### جدول الـ Validators المتاحة

| Validator | الوصف | مثال |
|---|---|---|
| `Validators.required()` | حقل مطلوب | `Validators.required(message: 'مطلوب')` |
| `Validators.email()` | تحقق من صيغة البريد | `Validators.email()` |
| `Validators.website()` | تحقق من رابط صحيح | `Validators.website()` |
| `Validators.numeric()` | يجب أن يكون رقماً | `Validators.numeric()` |
| `Validators.minLength(n)` | حد أدنى لعدد الأحرف | `Validators.minLength(3)` |
| `Validators.maxLength(n)` | حد أقصى لعدد الأحرف | `Validators.maxLength(100)` |
| `Validators.range(min, max)` | نطاق رقمي | `Validators.range(min: 1, max: 100)` |
| `Validators.combine([...])` | دمج عدة validators (يتوقف عند أول خطأ) | `Validators.combine([required(), minLength(3)])` |

### خصائص `FormValidationState`

| الخاصية | الوصف |
|---|---|
| `field(key).error` | رسالة الخطأ (null = صحيح) |
| `field(key).touched` | هل تم لمس الحقل؟ |
| `field(key).validating` | هل يتم التحقق async حالياً؟ |
| `field(key).isValid` | هل الحقل صحيح؟ |
| `isValid` | كل الحقول صحيحة؟ |
| `isValidating` | أي حقل يتحقق async حالياً؟ |
| `canSubmit` | `isValid && !isValidating` |

---

## 5️⃣ Providers — ربط كل شيء بـ Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ───────────────── Repository ─────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return ProductRepository(api);
});

// ───────────────── Notifier (قائمة بسيطة) ─────────────────
final productNotifierProvider =
    NotifierProvider<ProductNotifier, BaseState<List<Product>>>(
  ProductNotifier.new,
);

// ───────────────── Notifier (مع Pagination) ─────────────────
final productPaginatedProvider =
    NotifierProvider<ProductPaginatedNotifier, BaseState<Paginated<Product>>>(
  ProductPaginatedNotifier.new,
);

// ───────────────── Validation Controller ─────────────────
final productValidationProvider =
    NotifierProvider<ProductValidationController, FormValidationState<ProductFields>>(
  ProductValidationController.new,
);

// ───────────────── Actions Provider (للقائمة البسيطة) ─────────────────
/// ✅ لسهولة الوصول إلى ActionStore في الـ listener
final productActionsProvider = Provider<ActionStore>((ref) {
  final notifier = ref.watch(productNotifierProvider.notifier);
  ref.watch(productNotifierProvider); // لتفعيل إعادة البناء عند تغير الـ actions
  return notifier.actions;
});
```

---

## 6️⃣ UI Layer — الشاشات

### شاشة القائمة — `AsyncView` + `ActionBuilder` + `listenForActions`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_platform_core/core.dart';
import 'package:app_platform_state/state.dart';
import 'package:app_platform_ui/ui.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {

  @override
  void initState() {
    super.initState();
    // ✅ تحميل البيانات عند فتح الشاشة
    Future.microtask(() {
      ref.read(productNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider);
    final notifier = ref.read(productNotifierProvider.notifier);

    // ─────────── ✅ Action Listener — للـ SnackBars والتنقل ───────────
    listenForActions(
      ref: ref,
      provider: productActionsProvider,
      reactions: {
        // 🗑️ عند نجاح الحذف
        ActionKey(ActionType.delete): ActionReaction(
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم الحذف بنجاح ✅')),
            );
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل الحذف: ${error.message} ❌')),
            );
          },
        ),

        // ➕ عند نجاح الإنشاء
        ActionKey(ActionType.create): ActionReaction(
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم الإنشاء بنجاح ✅')),
            );
            Navigator.pop(context); // رجوع بعد الإنشاء
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل الإنشاء: ${error.message} ❌')),
            );
          },
        ),
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('المنتجات')),

      // ─────────── ✅ AsyncView — يدير loading/error/empty/success ───────────
      body: AsyncView<List<Product>>(
        status: state.status,
        data: state.data,
        error: state.error,
        onLoading: () => const LoadingView(),
        onError: (error) => ErrorView(error: error),
        onEmpty: () => const Center(child: Text('لا توجد منتجات')),
        onSuccess: (products) => RefreshIndicator(
          onRefresh: () => notifier.load(),
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(product: product);
            },
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### كارت المنتج — `ActionBuilder`

```dart
class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productNotifierProvider.notifier);
    final state = ref.watch(productNotifierProvider);

    return Card(
      child: ListTile(
        title: Text(product.name),
        subtitle: Text('${product.price} ر.س'),

        // ─────────── ✅ زر الحذف مع ActionBuilder ───────────
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ─── زر التفعيل/الإلغاء ───
            ActionBuilder(
              store: notifier.actions,
              actionKey: ActionKey(
                product.isActive ? ActionType.deactivate : ActionType.activate,
                product.id.toString(),
              ),
              builder: (context, actionState) {
                if (actionState.isLoading) {
                  return const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return IconButton(
                  icon: Icon(
                    product.isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: product.isActive ? Colors.green : Colors.grey,
                  ),
                  onPressed: () =>
                    notifier.toggleActive(product.id, !product.isActive),
                );
              },
            ),

            // ─── زر الحذف ───
            ActionBuilder(
              store: notifier.actions,
              actionKey: ActionKey(ActionType.delete, product.id.toString()),
              builder: (context, actionState) {
                if (actionState.isLoading) {
                  return const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, notifier, product.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductNotifier notifier, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.deleteProduct(id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

---

### شاشة القائمة مع Pagination — `PaginatedListView`

```dart
class ProductPaginatedScreen extends ConsumerStatefulWidget {
  const ProductPaginatedScreen({super.key});

  @override
  ConsumerState<ProductPaginatedScreen> createState() =>
      _ProductPaginatedScreenState();
}

class _ProductPaginatedScreenState
    extends ConsumerState<ProductPaginatedScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productPaginatedProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productPaginatedProvider);
    final notifier = ref.read(productPaginatedProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('المنتجات')),
      body: AsyncView<Paginated<Product>>(
        status: state.status,
        data: state.data,
        error: state.error,
        onLoading: () => const LoadingView(),
        onError: (error) => ErrorView(error: error),
        onEmpty: () => const Center(child: Text('لا توجد منتجات')),
        onSuccess: (paginated) => RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // ✅ تحميل المزيد عند الوصول لنهاية القائمة
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                notifier.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: paginated.items.length + (paginated.hasNext ? 1 : 0),
              itemBuilder: (context, index) {
                // ─── آخر عنصر: مؤشر التحميل أو الخطأ ───
                if (index == paginated.items.length) {
                  if (paginated.paginationError != null) {
                    return Center(
                      child: TextButton(
                        onPressed: () => notifier.loadMore(),
                        child: Text('فشل التحميل، اضغط للمحاولة مرة أخرى'),
                      ),
                    );
                  }
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final product = paginated.items[index];
                return _ProductCard(product: product);
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### شاشة الفورم — إنشاء / تعديل مع Validation

```dart
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product; // null = إنشاء، non-null = تعديل

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController = TextEditingController(
      text: widget.product?.description,
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString(),
    );
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validationState = ref.watch(productValidationProvider);
    final validator = ref.read(productValidationProvider.notifier);
    final notifier = ref.read(productNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل المنتج' : 'إنشاء منتج'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ─────────── حقل الاسم (مطلوب + async validation) ───────────
            AppTextField(
              label: 'اسم المنتج',
              hint: 'أدخل اسم المنتج',
              prefixIcon: Icons.label,
              errorText: validationState.field(ProductFields.name).touched
                  ? validationState.field(ProductFields.name).error
                  : null,
              isLoading: validationState.field(ProductFields.name).validating,
              onChanged: (value) {
                // ✅ يتحقق sync فوراً + async بعد 400ms (debounced)
                validator.validateAsync(ProductFields.name);
              },
            ),
            const SizedBox(height: 16),

            // ─────────── حقل الوصف (اختياري) ───────────
            AppTextField(
              label: 'الوصف',
              hint: 'أدخل وصف المنتج (اختياري)',
              maxLines: 3,
              prefixIcon: Icons.description,
              errorText: validationState.field(ProductFields.description).touched
                  ? validationState.field(ProductFields.description).error
                  : null,
              onChanged: (value) {
                validator.validate(ProductFields.description);
              },
            ),
            const SizedBox(height: 16),

            // ─────────── حقل السعر (رقمي + نطاق) ───────────
            AppTextField(
              label: 'السعر',
              hint: '0.00',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              errorText: validationState.field(ProductFields.price).touched
                  ? validationState.field(ProductFields.price).error
                  : null,
              onChanged: (value) {
                validator.validate(ProductFields.price);
              },
            ),
            const SizedBox(height: 16),

            // ─────────── حقل الإيميل ───────────
            AppTextField(
              label: 'البريد الإلكتروني',
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email,
              errorText: validationState.field(ProductFields.email).touched
                  ? validationState.field(ProductFields.email).error
                  : null,
              onChanged: (value) {
                validator.validate(ProductFields.email);
              },
            ),
            const SizedBox(height: 16),

            // ─────────── حقل الموقع ───────────
            AppTextField(
              label: 'الموقع الإلكتروني',
              hint: 'https://example.com',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.language,
              errorText: validationState.field(ProductFields.website).touched
                  ? validationState.field(ProductFields.website).error
                  : null,
              onChanged: (value) {
                validator.validate(ProductFields.website);
              },
            ),
            const SizedBox(height: 32),

            // ─────────── زر الحفظ ───────────
            SizedBox(
              width: double.infinity,
              child: ActionBuilder(
                store: notifier.actions,
                actionKey: ActionKey(
                  isEdit ? ActionType.update : ActionType.create,
                  isEdit ? widget.product!.id.toString() : null,
                ),
                builder: (context, actionState) {
                  return ElevatedButton(
                    onPressed: actionState.isLoading || !validationState.canSubmit
                        ? null
                        : () => _submit(validator, notifier),
                    child: actionState.isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEdit ? 'حفظ التعديلات' : 'إنشاء المنتج'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(
    ProductValidationController validator,
    ProductNotifier notifier,
  ) {
    // ✅ تحقق من كل الحقول قبل الإرسال
    final isValid = validator.validateAll();
    if (!isValid) return;

    final body = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
    };

    if (isEdit) {
      notifier.updateProduct(widget.product!.id, body);
    } else {
      notifier.createProduct(body);
    }
  }
}
```

---

### البديل: استخدام `BaseState.when` extension

```dart
// بدلاً من AsyncView يمكنك استخدام extension method
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(productNotifierProvider);

  return state.when(
    loading: () => const LoadingView(),
    error: (error) => ErrorView(error: error),
    success: (data) => ListView.builder(
      itemCount: data.length,
      itemBuilder: (_, i) => Text(data[i].name),
    ),
  );
}
```

---

### استخدام `preFetch` — لتحميل بيانات قبل التنقل

```dart
// ✅ مثال: تحميل التفاصيل قبل فتح شاشة التفاصيل
void _openDetails(BuildContext context, WidgetRef ref, int productId) {
  ref.preFetch<Product>(
    task: () => ref.read(productRepositoryProvider).fetchOne(productId),
    onLoading: () {
      showDialog(
        context: context,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    },
    onSuccess: (product) {
      Navigator.pop(context); // أغلق الـ loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    },
    onError: (error) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    },
  );
}
```

---

## 7️⃣ التعامل مع أخطاء السيرفر (ValidationError)

```dart
// ✅ عند 422 — السيرفر يرجع أخطاء حقول محددة
onError: (error) {
  if (error is ValidationError && error.fields != null) {
    final validator = ref.read(productValidationProvider.notifier);

    // ربط أخطاء السيرفر بالحقول
    error.fields!.forEach((field, messages) {
      final fieldKey = ProductFields.values.firstWhere(
        (f) => f.name == field,
        orElse: () => ProductFields.name,
      );
      validator.setFieldValidation(
        fieldKey,
        error: messages is List ? messages.first : messages.toString(),
      );
    });
  }
},
```

---

## 8️⃣ تحقق متعدد الخطوات (`Stepper Validation`)

```dart
// ✅ للفورمات متعددة الخطوات (Wizard / Stepper)
void _nextStep(ProductValidationController validator) {
  // تحقق فقط من حقول الخطوة الحالية
  final isStepValid = validator.validateStep([
    ProductFields.name,
    ProductFields.description,
  ]);

  if (isStepValid) {
    setState(() => _currentStep++);
  }
}
```

---

## 📊 مرجع سريع — ActionType المتاحة

| ActionType | الاستخدام |
|---|---|
| `ActionType.create` | إنشاء عنصر جديد |
| `ActionType.update` | تعديل عنصر |
| `ActionType.delete` | حذف عنصر |
| `ActionType.check` | فحص (مثل التحقق من الصلاحية) |
| `ActionType.validate` | تحقق من صحة البيانات |
| `ActionType.submit` | إرسال فورم |
| `ActionType.save` | حفظ مسودة |
| `ActionType.activate` | تفعيل |
| `ActionType.deactivate` | إلغاء تفعيل |
| `ActionType.archive` | أرشفة |
| `ActionType.restore` | استعادة من الأرشيف |
| `ActionType.login` | تسجيل دخول |
| `ActionType.logout` | تسجيل خروج |
| `ActionType.upload` | رفع ملف |

---

## 📊 مرجع سريع — Error Types

| Error | المعنى | HTTP Code |
|---|---|---|
| `NoInternetError` | لا يوجد اتصال بالإنترنت | — |
| `TimeoutError` | انتهت مهلة الطلب | — |
| `UnauthorizedError` | غير مصرح (التوكن منتهي) | 401 |
| `ForbiddenError` | ممنوع الوصول | 403 |
| `NotFoundError` | المورد غير موجود | 404 |
| `ValidationError` | خطأ في البيانات المرسلة | 422 |
| `ServerError` | خطأ في السيرفر | 500+ |
| `NetworkError` | خطأ شبكة عام | — |
| `UnknownError` | خطأ غير معروف | — |

---

## 🏁 Checklist الكامل

### Data Layer
- [ ] Model مع `fromJson` و `toJson`
- [ ] `copyWith` في الموديل
- [ ] Repository يغطي كل العمليات (CRUD)
- [ ] كل دالة في الـ Repository ترجع `Result<T>`

### State Layer
- [ ] Notifier يرث `BaseNotifier<T>` أو `PaginatedNotifier<T>`
- [ ] `ActionMixin` مضاف إذا يوجد actions
- [ ] `runAction` مستخدم لكل action (delete, create, update, toggle...)
- [ ] `ActionKey` فريد لكل action (مع `id` إذا per-item)

### Validation Layer
- [ ] `enum` للحقول
- [ ] `ValidationController` مع `init()` في `build()`
- [ ] Sync validators لكل حقل مطلوب
- [ ] Async validators إذا يحتاج تحقق من السيرفر
- [ ] `validateAll()` قبل الـ submit
- [ ] `validateStep()` للفورمات متعددة الخطوات
- [ ] ربط أخطاء السيرفر عبر `setFieldValidation()`

### Providers
- [ ] Repository Provider
- [ ] Notifier Provider (`NotifierProvider`)
- [ ] Validation Provider
- [ ] Actions Provider (للـ listener)

### UI Layer
- [ ] `AsyncView` لعرض حالات loading/error/empty/success
- [ ] `ActionBuilder` لكل زر له action
- [ ] `listenForActions` للـ SnackBars والتنقل
- [ ] `AppTextField` مع `errorText` و `isLoading`
- [ ] عرض الأخطاء فقط بعد `touched`
- [ ] `RefreshIndicator` للتحديث بالسحب
- [ ] Pagination scroll listener (إذا paginated)
- [ ] `preFetch` إذا يحتاج تحميل قبل التنقل
- [ ] حوار تأكيد قبل الحذف

# مهارة: بناء شاشة تقرير باستخدام Riverpod + app_platform

## هيكل المجلدات (Feature-First)

```
features/<domain>/reports/<report_name>/
├── models/
│   ├── <report>_model.dart                  # نموذج استجابة API
│   ├── <report>_state_model.dart            # نموذج حالة الفلتر (filter state)
│   ├── <report>_fields.dart                 # Enum للحقول المستخدمة في validation
│   ├── <report>_account_card.dart           # نموذج لعنصر القائمة (إن وجد)
│   └── models.dart                          # Barrel export
├── providers/
│   ├── list_<report>_notifier.dart          # جلب البيانات (BaseNotifier)
│   ├── <report>_state_notifier.dart         # إدارة حالة الفلتر
│   ├── <report>_permissions_notifier.dart   # صلاحيات المستخدم
│   ├── <report>_validations_notifier.dart   # التحقق من صحة المدخلات
│   └── providers.dart                       # Barrel export
├── repositories/
│   ├── <report>_repository.dart             # Interface
│   └── <report>_repository_impl.dart        # التنفيذ + Provider
└── presentation/
    ├── screens/
    │   ├── <report>_screen.dart             # الشاشة الرئيسية
    │   └── <report>_filters_screen.dart     # شاشة الفلاتر
    └── widgets/
        ├── <report>_main_account_card.dart  # كرت عرض البيانات
        ├── printing_<report>_report.dart    # طباعة PDF
        └── export_<report>_report.dart      # تصدير Excel
```

---

## 1. نموذج حالة API (`<report>_model.dart`)

```dart
import 'package:dart_mappable/dart_mappable.dart';

part '<report>_model.mapper.dart';

@MappableClass()
class ReportModel with ReportModelMappable {
  ReportModel({required this.items});

  @MappableField(key: 'Items')
  final List<ReportItem> items;

  static const fromMap = ReportModelMapper.fromMap;
}
```

---

## 2. نموذج حالة الفلتر (`<report>_state_model.dart`)

يُستخدم `dart_mappable` مع `GenerateMethods.copy` فقط، لأن我们没有 need لتسلسل JSON لحالة الفلتر.

```dart
import 'package:dart_mappable/dart_mappable.dart';

part '<report>_state_model.mapper.dart';

@MappableClass(generateMethods: GenerateMethods.copy)
class ReportStateModel with ReportStateModelMappable {
  ReportStateModel({
    this.fromDate,
    this.toDate,
    this.selectedBranches,
    this.isFiltersOpen = false,
    // ... باقي الحقول
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final List<BranchModel>? selectedBranches;
  final bool isFiltersOpen;
  // ... باقي الحقول
}
```

> **ملاحظة:** `GenerateMethods.copy` يولّد فقط `copyWith` بدون `toMap`/`fromMap`.

---

## 3. حقول Validation (`<report>_fields.dart`)

```dart
enum ReportFields {
  fromDate,
  toDate,
  branches,
  costCenters,
  entryStatus,
}
```

---

## 4. State Notifier — إدارة حالة الفلتر

```dart
final reportStateProvider = NotifierProvider.autoDispose<
    ReportStateNotifier, ReportStateModel>(
  ReportStateNotifier.new,
);

class ReportStateNotifier extends Notifier<ReportStateModel> {
  @override
  ReportStateModel build() {
    // القيم الابتدائية: تواريخ السنة المالية الحالية إلخ.
    return ReportStateModel(
      fromDate: initialFromDate,
      toDate: initialToDate,
    );
  }

  void setFromDate(DateTime? date) => state = state.copyWith(fromDate: date);
  void setToDate(DateTime? date) => state = state.copyWith(toDate: date);
  void setSelectedBranches(List<BranchModel>? branches) =>
      state = state.copyWith(selectedBranches: branches);
  void toggleFiltersOpen() =>
      state = state.copyWith(isFiltersOpen: !state.isFiltersOpen);
  // ... باقي الـ setters
}
```

> **القاعدة:** كل متغير في `StateModel` له setter في `StateNotifier` مع clear إذا كان optional.

---

## 5. List Notifier — جلب البيانات (Async)

```dart
final listReportProvider = NotifierProvider.autoDispose<
    ListReportNotifier, BaseState<ReportModel>>(
  ListReportNotifier.new,
);

class ListReportNotifier extends BaseNotifier<ReportModel> {
  late ReportRepository _repository;

  @override
  BaseState<ReportModel> build() {
    _repository = ref.read(reportRepositoryProvider);
    Future.microtask(getData); // جلب تلقائي عند بناء الـ provider
    return const BaseState();
  }

  Future<void> getData() async {
    setLoading();

    final state = ref.read(reportStateProvider);
    final result = await _repository.getData(
      fromDate: state.fromDate!,
      toDate: state.toDate!,
      branchesIds: state.selectedBranches?.map((e) => e.id!).toList(),
    );

    result.when(
      success: (data) => setSuccess(data),
      failure: (error) => setError(error),
    );
  }
}
```

> **ملاحظات:**
> - `BaseNotifier<T>` يوفر `setLoading()`، `setSuccess(T)`، `setError(AppError)`
> - `BaseState<T>` يحوي `LoadStatus` (idle, loading, success, error) و `T? data` و `AppError? error`
> - يُستخدم `Future.microtask` في `build()` لتفادي استدعاء async داخل الـ build

---

## 6. Permissions Notifier — صلاحيات المستخدم

```dart
final reportPermissionsProvider = NotifierProvider.autoDispose<
    ReportPermissionsNotifier, BaseState<List<int>>>(
  ReportPermissionsNotifier.new,
);

class ReportPermissionsNotifier extends BaseNotifier<List<int>> {
  late UsersRepository _repository;

  List<int> permissions = [];
  bool canAccess = false, canPrint = false, canExport = false;

  @override
  BaseState<List<int>> build() {
    _repository = ref.read(usersRepositoryProvider);
    Future.microtask(getPermissions);
    return const BaseState();
  }

  Future<void> getPermissions() async {
    setLoading();
    final result = await _repository.getUserPermissions(Module.ReportId);

    switch (result) {
      case Success(:final data):
        permissions = data;
        canAccess = _has(SystemPermissions.Access);
        canExport = _has(SystemPermissions.Export);
        canPrint = _has(SystemPermissions.Print);
        setSuccess(data);
      case Failure(:final error):
        setError(error);
    }
  }

  bool _has(int permissionId) => permissions.contains(permissionId);
}
```

---

## 7. Validation Controller — التحقق من صحة المدخلات

```dart
final reportValidationsProvider = NotifierProvider.autoDispose<
    ReportValidationsNotifier, FormValidationState<ReportFields>>(
  ReportValidationsNotifier.new,
);

class ReportValidationsNotifier extends ValidationController<ReportFields> {
  @override
  FormValidationState<ReportFields> build() {
    init(validators: {
      ReportFields.fromDate: (context) {
        final data = context.read(reportStateProvider);
        return requiredObjectValidator(data.fromDate);
      },
      ReportFields.toDate: (context) {
        final data = context.read(reportStateProvider);
        if (data.fromDate != null && data.toDate != null) {
          if (data.fromDate!.isAfter(data.toDate!)) {
            return 'البداية لا يمكن أن تكون بعد النهاية';
          }
        }
        return null;
      },
    });
    return state;
  }

  void validateFromDate() => validate(ReportFields.fromDate);
  void validateToDate() => validate(ReportFields.toDate);
  bool validateForm() => validateAll();
}
```

**الميثودز المتاحة في `ValidationController`:**
| الميثود | الوظيفة |
|---------|---------|
| `validate(K field)` | تحقق من حقل + تعليمه كـ touched |
| `validateAll()` | تحقق من كل الحقول، يرجع `true` إذا الكل صحيح |
| `validateStep(List<K>)` | تحقق من مجموعة حقول |
| `reset()` | إعادة تعيين حالة التحقق |
| `touch(K field)` | تعليم حقل كـ touched بدون تحقق |
| `requiredObjectValidator(value)` | تحقق من أن القيمة غير null |

---

## 8. Repository — طبقة البيانات

### Interface
```dart
abstract class ReportRepository {
  Future<Result<ReportModel>> getData({
    required DateTime fromDate,
    required DateTime toDate,
    List<int>? branchesIds,
  });
}
```

### Implementation + Provider
```dart
final reportRepositoryProvider = Provider<ReportRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportRepositoryImpl(apiClient: apiClient);
});

class ReportRepositoryImpl implements ReportRepository {
  final ApiClient apiClient;

  ReportRepositoryImpl({required this.apiClient});

  @override
  Future<Result<ReportModel>> getData({
    required DateTime fromDate,
    required DateTime toDate,
    List<int>? branchesIds,
  }) async {
    final query = <String, dynamic>{};
    query['fromDate'] = fromDate.toIso8601String();
    query['toDate'] = toDate.toIso8601String();

    return apiClient.getDecompressed<ReportModel>(
      '/${EndPoint.domain}/${EndPoint.reports}/report-endpoint',
      query: query,
      parser: (fileBytes) {
        final jsonString = utf8.decode(fileBytes);
        return ReportModel.fromMap(jsonDecode(jsonString));
      },
    );
  }
}
```

> `ApiClient.getDecompressed<T>` يفك ضغط gzip ويستخدم الـ parser لتحويل الاستجابة إلى النموذج المطلوب.

---

## 9. الشاشة الرئيسية — Screen

```dart
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listReportProvider);
    final permissionsState = ref.watch(reportPermissionsProvider);
    final permissionsNotifier = ref.watch(reportPermissionsProvider.notifier);

    return Scaffold(
      appBar: CAppBar(
        title: Strings.reportTitle.value,
        actions: [
          if (permissionsNotifier.canExport)
            CIconButton(
              icon: SvgIcons.export,
              onTap: () => onExport(context),
            ),
          if (permissionsNotifier.canPrint)
            CIconButton(
              icon: SvgIcons.print,
              onTap: () => onPrint(context),
            ),
        ],
      ),
      body: AsyncView<List<int>>(
        status: permissionsState.status,
        data: permissionsState.data,
        error: permissionsState.error,
        onSuccess: (context, _) => Padding(
          padding: EdgeInsets.symmetric(horizontal: CSpacing.space5),
          child: SafeArea(
            child: AsyncView<ReportModel>(
              status: state.status,
              data: state.data,
              error: state.error,
              onSuccess: (_, data) => ListView(
                children: data.items.map((item) => ItemCard(item: item)).toList(),
              ),
              onErrorAction: () =>
                  ref.watch(listReportProvider.notifier).getData(),
            ),
          ),
        ),
      ),
    );
  }

  void onPrint(BuildContext context) { /* ... */ }
  void onExport(BuildContext context) { /* ... */ }
}
```

**النقاط المهمة:**
- `AsyncView` متداخل: الأول للـ permissions والثاني للبيانات
- أزرار الـ AppBar تظهر/تخفي حسب الصلاحيات
- `onErrorAction` يعيد جلب البيانات عند الضغط على زر إعادة المحاولة

---

## 10. AsyncView — معالجة الحالات

```dart
AsyncView<T>(
  status: state.status,     // LoadStatus: idle, loading, success, error
  data: state.data,         // T? — البيانات
  error: state.error,       // AppError? — الخطأ
  onSuccess: (context, data) => Widget,   // required
  onLoading: (context) => Widget,         // اختياري (افتراضي: CircularProgressIndicator)
  onError: (context, error) => Widget,    // اختياري (افتراضي: رسالة خطأ + زر refresh)
  onEmpty: (context) => Widget,           // اختياري (افتراضي: 'No data available')
  onErrorAction: () => fn,                // اختياري: دالة إعادة المحاولة
);
```

---

## 11. طباعة PDF

```dart
class PrintingReport {
  final List<ItemModel> items;
  final FacilityDataForPrint facilityData;
  final DateTime fromDate;
  final DateTime toDate;

  PrintingReport({
    required this.items,
    required this.facilityData,
    required this.fromDate,
    required this.toDate,
  });

  Future<void> printReport() async {
    final pdf = await _generatePdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Document> _generatePdf() async {
    // استخدم مكتبة pdf لبناء التقرير
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // محتوى التقرير
        ],
      ),
    );
    return doc;
  }
}
```

---

## 12. تصدير Excel

```dart
class ExportReport {
  void exportReportExcelFile(List<ItemModel> items) {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    // إضافة header
    sheet.appendRow(['الاسم', 'الرصيد', 'الحالة']);

    // إضافة البيانات
    for (final item in items) {
      sheet.appendRow([item.name, item.balance, item.status]);
    }

    // حفظ ومشاركة الملف
    final fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/report.xlsx');
    file.writeAsBytes(fileBytes!);
    Share.shareXFiles([XFile(file.path)]);
  }
}
```

---

## 13. ملخص الـ Providers المستخدمة لكل شاشة

| Provider | النوع | الوظيفة |
|----------|------|---------|
| `reportStateProvider` | `NotifierProvider.autoDispose<StateNotifier, StateModel>` | حالة الفلاتر |
| `listReportProvider` | `NotifierProvider.autoDispose<ListNotifier, BaseState<Model>>` | البيانات من API |
| `reportPermissionsProvider` | `NotifierProvider.autoDispose<PermissionsNotifier, BaseState<List<int>>>` | صلاحيات المستخدم |
| `reportValidationsProvider` | `NotifierProvider.autoDispose<ValidationNotifier, FormValidationState<Fields>>` | التحقق من المدخلات |
| `reportRepositoryProvider` | `Provider<RepositoryImpl>` | إنشاء Repository |

---

## 14. تسلسل العمل

```
Screen تفتح
  ↓
PermissionsNotifier.build() → Future.microtask(getPermissions)
  ↓
StateNotifier.build() → القيم الابتدائية من ValidationController
  ↓
ListNotifier.build() → Future.microtask(getData) → يقرأ StateNotifier → يستدعي Repository
  ↓
Repository → ApiClient.getDecompressed<T>(...) → يرجع Result<T>
  ↓
ListNotifier → setSuccess(data) أو setError(error)
  ↓
AsyncView يعرض: success → محتوى | error → رسالة خطأ + إعادة محاولة | loading → مؤشر تحميل
```

---

## 15. قواعد ذهبية

1. **لا تستخدم `ref.read` في `build`** — استخدم `ref.watch` في الـ build و `ref.read` في callback خارج الـ build
2. **كل StateNotifier فيه setter لكل حقل** مع clear إذا كان الحقل optional
3. **Permissions تأتي أولاً** — لأن الأزرار في AppBar تعتمد عليها
4. **`Future.microtask`** في build للـ async calls عشان نتجنب استدعاء async داخل الـ build
5. **`dart_mappable` مع `GenerateMethods.copy`** لنماذج state عشان `copyWith` بدون JSON serialization
6. **Barrel files** (`models.dart`, `providers.dart`) — كل مجلد عنده barrel يصدر كل شيء

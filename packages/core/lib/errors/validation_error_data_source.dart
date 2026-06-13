
class ValidationErrorDataSource{
  String? name,
  location;

  ValidationErrorDataSource.fromJson(Map<String, dynamic> jsonMap):
        name = jsonMap['name'],
        location = jsonMap['location'];
}
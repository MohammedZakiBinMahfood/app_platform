
enum ErrorType{
  serverError,
  internetConnectionError,
  mapperError,
  timeOutError,
  unauthorizedError,
  forbiddenError,
  notFoundError,
  unknownError,
  badRequestError,
}
abstract class AppError<T> {
  final ErrorType type;
  final T data;
  const AppError(this.type,this.data);

  String get errorMessage{
    switch(type){
      case ErrorType.unauthorizedError:
        return 'Unauthorized';
      case ErrorType.forbiddenError:
        return 'Forbidden';
      case ErrorType.badRequestError:
        return 'Bad Request';
      default:
        return data?.toString() ?? 'NAN';
    }


  }
}

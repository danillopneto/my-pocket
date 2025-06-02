// Generic Firestore error logger utility
// ignore_for_file: avoid_print

Stream<T> logFirestoreStreamErrors<T>(Stream<T> stream, {String? context}) {
  return stream.handleError((error, stack) {
    print('Firestore error${context != null ? ' [$context]' : ''}:');
    print(error);
    print(stack);
  });
}

Future<T> logFirestoreFutureErrors<T>(Future<T> future, {String? context}) {
  return future.catchError((error, stack) {
    print('Firestore error${context != null ? ' [$context]' : ''}:');
    print(error);
    print(stack);
    throw error;
  });
}

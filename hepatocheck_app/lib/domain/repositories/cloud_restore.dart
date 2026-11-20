class RestoreReport {
  const RestoreReport({
    this.drinks = 0,
    this.exams = 0,
    this.goals = 0,
    this.unreadable = 0,
  });

  final int drinks;
  final int exams;
  final int goals;
  final int unreadable;

  int get total => drinks + exams + goals;
}

abstract interface class RestorableRepository<T> {
  List<T> getAll();

  Future<void> restore(T item);
}

abstract interface class CloudRestore {
  Future<RestoreReport> restore(String uid);

  Future<void> deleteRemote(String uid, {bool includeKey = false});
}

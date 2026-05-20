abstract interface class FilterDao<TFilter, TResult> {
  Future<List<TResult>> getFiltered(TFilter filter);

  Future<int> countFiltered(TFilter filter);
}

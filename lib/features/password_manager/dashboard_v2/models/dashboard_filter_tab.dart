enum DashboardFilterTab {
  active('Активные'),
  favorites('Избранные'),
  frequentlyUsed('Часто используемые'),
  archived('Архив'),
  deleted('Удаленные');

  const DashboardFilterTab(this.label);

  final String label;
}

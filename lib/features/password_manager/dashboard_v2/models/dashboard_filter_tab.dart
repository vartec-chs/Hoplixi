enum DashboardFilterTab {
  active('Активные'),
  favorites('Избранные'),
  pinned('Закрепленные'),
  archived('Архив'),
  deleted('Удаленные');

  const DashboardFilterTab(this.label);

  final String label;
}

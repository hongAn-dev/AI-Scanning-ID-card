enum DiscountType {
  vnd,
  percent;

  String get label {
    switch (this) {
      case DiscountType.vnd:
        return 'VND';
      case DiscountType.percent:
        return '%';
    }
  }
}

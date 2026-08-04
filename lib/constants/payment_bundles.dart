/// Checkout bundle options for multi-week / full-season prepaid entry.
class PaymentBundle {
  final String id;
  final String label;
  final String description;
  final int weekCount;
  final double price;

  const PaymentBundle({
    required this.id,
    required this.label,
    required this.description,
    required this.weekCount,
    required this.price,
  });

  double get perWeek => price / weekCount;

  static const single = PaymentBundle(
    id: 'single',
    label: 'This week only',
    description: 'One week entry',
    weekCount: 1,
    price: 10,
  );

  static const three = PaymentBundle(
    id: 'bundle_3',
    label: '3-week bundle',
    description: 'Pay for 3 weeks upfront — save \$3',
    weekCount: 3,
    price: 27,
  );

  static const five = PaymentBundle(
    id: 'bundle_5',
    label: '5-week bundle',
    description: 'Pay for 5 weeks upfront — save \$10',
    weekCount: 5,
    price: 40,
  );

  static const fullSeason = PaymentBundle(
    id: 'full_season',
    label: 'Full season',
    description: 'All 18 regular-season weeks — best value',
    weekCount: 18,
    price: 150,
  );

  static const List<PaymentBundle> all = [
    single,
    three,
    five,
    fullSeason,
  ];

  static PaymentBundle byId(String? id) {
    return all.firstWhere(
      (b) => b.id == id,
      orElse: () => single,
    );
  }
}

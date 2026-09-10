import 'package:intl/intl.dart';

/// Format Rupiah, contoh: 5.000.000 → "Rp5.000.000".
String rupiah(num value) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(value);
}
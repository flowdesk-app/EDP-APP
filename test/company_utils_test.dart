import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/utils/company_utils.dart';

void main() {
  test('Moves Ponneri items to RANE PONNERI', () {
    final item1 = 'RANE MADRAS LTD PONNERI -L10 MODEL-2';
    final item2 = 'RANE MADRAS LTD PONEERI-L10 MODEL-1';

    final res1 = getCompaniesForPrefix(item1);
    final res2 = getCompaniesForPrefix(item2);

    expect(res1, contains('RANE PONNERI'));
    expect(res2, contains('RANE PONNERI'));
    expect(res1, isNot(contains('rane')));
    expect(res2, isNot(contains('rane')));
  });
}

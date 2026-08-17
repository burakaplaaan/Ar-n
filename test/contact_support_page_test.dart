import 'package:arin/presentation/settings/contact_support_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatContactDeviceLabel birleştirir ve tekrar etmez', () {
    expect(
      formatContactDeviceLabel(brand: 'Samsung', model: 'SM-S911B'),
      'Samsung SM-S911B',
    );
    expect(
      formatContactDeviceLabel(brand: 'Xiaomi', model: 'Xiaomi 2312DRA50G'),
      'Xiaomi 2312DRA50G',
    );
    expect(formatContactDeviceLabel(brand: 'iPhone', model: ''), 'iPhone');
    expect(formatContactDeviceLabel(brand: '', model: 'Pixel 8'), 'Pixel 8');
    expect(formatContactDeviceLabel(brand: '  ', model: '  '), '');
  });

  test('contactDeviceBrand Android yedek adını markaya düşürür', () {
    expect(
      contactDeviceBrand(displayName: 'Samsung', brand: 'samsung'),
      'Samsung',
    );
    expect(
      contactDeviceBrand(displayName: 'Android', brand: 'google'),
      'google',
    );
    expect(
      formatContactDeviceLabel(
        brand: contactDeviceBrand(displayName: 'Android', brand: 'google'),
        model: 'Pixel 8',
      ),
      'google Pixel 8',
    );
  });
}

class Country {
  final String code;   // ISO
  final String dial;   // +93, +98, ...
  final String nameFa; // نام برای نمایش
  const Country(this.code, this.dial, this.nameFa);
}

const countries = <Country>[
  Country('AF', '+93',  'افغانستان'),
  Country('IR', '+98',  'ایران'),
  Country('TR', '+90',  'ترکیه'),
  Country('DE', '+49',  'آلمان'),
  Country('AE', '+971', 'امارات'),
  Country('US', '+1',   'ایالات متحده'),
  Country('GB', '+44',  'بریتانیا'),
];

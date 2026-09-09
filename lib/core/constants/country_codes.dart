class CountryCodeItem {
  final String code;
  final String country;
  final String flag;

  const CountryCodeItem({
    required this.code,
    required this.country,
    required this.flag,
  });
}

/// Dubai / UAE (+971) is the primary default country code.
const CountryCodeItem kDefaultCountryCode = CountryCodeItem(
  code: '+971',
  country: 'Dubai, UAE',
  flag: '🇦🇪',
);

const List<CountryCodeItem> kCountryCodes = [
  CountryCodeItem(code: '+971', country: 'Dubai, UAE', flag: '🇦🇪'),
  CountryCodeItem(code: '+966', country: 'Saudi Arabia', flag: '🇸🇦'),
  CountryCodeItem(code: '+974', country: 'Qatar', flag: '🇶🇦'),
  CountryCodeItem(code: '+965', country: 'Kuwait', flag: '🇰🇼'),
  CountryCodeItem(code: '+973', country: 'Bahrain', flag: '🇧🇭'),
  CountryCodeItem(code: '+968', country: 'Oman', flag: '🇴🇲'),
  CountryCodeItem(code: '+1', country: 'USA / Canada', flag: '🇺🇸'),
  CountryCodeItem(code: '+44', country: 'United Kingdom', flag: '🇬🇧'),
  CountryCodeItem(code: '+91', country: 'India', flag: '🇮🇳'),
  CountryCodeItem(code: '+92', country: 'Pakistan', flag: '🇵🇰'),
  CountryCodeItem(code: '+20', country: 'Egypt', flag: '🇪🇬'),
  CountryCodeItem(code: '+961', country: 'Lebanon', flag: '🇱🇧'),
  CountryCodeItem(code: '+962', country: 'Jordan', flag: '🇯🇴'),
  CountryCodeItem(code: '+33', country: 'France', flag: '🇫🇷'),
  CountryCodeItem(code: '+49', country: 'Germany', flag: '🇩🇪'),
  CountryCodeItem(code: '+39', country: 'Italy', flag: '🇮🇹'),
  CountryCodeItem(code: '+34', country: 'Spain', flag: '🇪🇸'),
  CountryCodeItem(code: '+7', country: 'Russia', flag: '🇷🇺'),
  CountryCodeItem(code: '+86', country: 'China', flag: '🇨🇳'),
  CountryCodeItem(code: '+81', country: 'Japan', flag: '🇯🇵'),
  CountryCodeItem(code: '+65', country: 'Singapore', flag: '🇸🇬'),
  CountryCodeItem(code: '+61', country: 'Australia', flag: '🇦🇺'),
  CountryCodeItem(code: '+90', country: 'Turkey', flag: '🇹🇷'),
  CountryCodeItem(code: '+212', country: 'Morocco', flag: '🇲🇦'),
  CountryCodeItem(code: '+216', country: 'Tunisia', flag: '🇹🇳'),
  CountryCodeItem(code: '+213', country: 'Algeria', flag: '🇩🇿'),
];

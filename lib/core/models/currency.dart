class Currency {
  final String code, name, symbol;
  const Currency(this.code, this.name, this.symbol);
}

const List<Currency> worldCurrencies = [

  // A
  Currency('AFN', 'Afghan Afghani', '؋'),
  Currency('ALL', 'Albanian Lek', 'L'),
  Currency('DZD', 'Algerian Dinar', 'د.ج'),
  Currency('AOA', 'Angolan Kwanza', 'Kz'),
  Currency('ARS', 'Argentine Peso', '\$'),
  Currency('AMD', 'Armenian Dram', '֏'),
  Currency('AWG', 'Aruban Florin', 'ƒ'),
  Currency('AUD', 'Australian Dollar', 'A\$'),
  Currency('AZN', 'Azerbaijani Manat', '₼'),

  // B
  Currency('BSD', 'Bahamian Dollar', '\$'),
  Currency('BHD', 'Bahraini Dinar', '.د.ب'),
  Currency('BDT', 'Bangladeshi Taka', '৳'),
  Currency('BBD', 'Barbadian Dollar', '\$'),
  Currency('BYN', 'Belarusian Ruble', 'Br'),
  Currency('BZD', 'Belize Dollar', '\$'),
  Currency('BMD', 'Bermudian Dollar', '\$'),
  Currency('BTN', 'Bhutanese Ngultrum', 'Nu.'),
  Currency('BOB', 'Bolivian Boliviano', 'Bs.'),
  Currency('BAM', 'Bosnia Convertible Mark', 'KM'),
  Currency('BWP', 'Botswana Pula', 'P'),
  Currency('BRL', 'Brazilian Real', 'R\$'),
  Currency('BND', 'Brunei Dollar', '\$'),
  Currency('BGN', 'Bulgarian Lev', 'лв'),
  Currency('BIF', 'Burundian Franc', 'FBu'),

  // C
  Currency('KHR', 'Cambodian Riel', '៛'),
  Currency('CAD', 'Canadian Dollar', 'C\$'),
  Currency('CVE', 'Cape Verdean Escudo', '\$'),
  Currency('XAF', 'Central African CFA Franc', 'FCFA'),
  Currency('CLP', 'Chilean Peso', '\$'),
  Currency('CNY', 'Chinese Yuan', '¥'),
  Currency('COP', 'Colombian Peso', '\$'),
  Currency('KMF', 'Comorian Franc', 'CF'),
  Currency('CDF', 'Congolese Franc', 'FC'),
  Currency('CRC', 'Costa Rican Colón', '₡'),
  Currency('HRK', 'Croatian Kuna', 'kn'),
  Currency('CUP', 'Cuban Peso', '\$'),
  Currency('CZK', 'Czech Koruna', 'Kč'),

  // D
  Currency('DKK', 'Danish Krone', 'kr'),
  Currency('DJF', 'Djiboutian Franc', 'Fdj'),
  Currency('DOP', 'Dominican Peso', 'RD\$'),

  // E
  Currency('EGP', 'Egyptian Pound', '£'),
  Currency('ERN', 'Eritrean Nakfa', 'Nfk'),
  Currency('ETB', 'Ethiopian Birr', 'Br'),
  Currency('EUR', 'Euro', '€'),

  // F
  Currency('FJD', 'Fijian Dollar', '\$'),

  // G
  Currency('GMD', 'Gambian Dalasi', 'D'),
  Currency('GEL', 'Georgian Lari', '₾'),
  Currency('GHS', 'Ghanaian Cedi', '₵'),
  Currency('GIP', 'Gibraltar Pound', '£'),
  Currency('GTQ', 'Guatemalan Quetzal', 'Q'),
  Currency('GNF', 'Guinean Franc', 'FG'),
  Currency('GYD', 'Guyanese Dollar', '\$'),

  // H
  Currency('HTG', 'Haitian Gourde', 'G'),
  Currency('HNL', 'Honduran Lempira', 'L'),
  Currency('HKD', 'Hong Kong Dollar', 'HK\$'),
  Currency('HUF', 'Hungarian Forint', 'Ft'),

  // I
  Currency('ISK', 'Icelandic Króna', 'kr'),
  Currency('INR', 'Indian Rupee', '₹'),
  Currency('IDR', 'Indonesian Rupiah', 'Rp'),
  Currency('IRR', 'Iranian Rial', '﷼'),
  Currency('IQD', 'Iraqi Dinar', 'ع.د'),
  Currency('ILS', 'Israeli Shekel', '₪'),

  // J
  Currency('JMD', 'Jamaican Dollar', '\$'),
  Currency('JPY', 'Japanese Yen', '¥'),
  Currency('JOD', 'Jordanian Dinar', 'د.ا'),

  // K
  Currency('KZT', 'Kazakhstani Tenge', '₸'),
  Currency('KES', 'Kenyan Shilling', 'KSh'),
  Currency('KWD', 'Kuwaiti Dinar', 'د.ك'),
  Currency('KGS', 'Kyrgyzstani Som', 'с'),

  // L
  Currency('LAK', 'Lao Kip', '₭'),
  Currency('LBP', 'Lebanese Pound', 'ل.ل'),
  Currency('LSL', 'Lesotho Loti', 'L'),
  Currency('LRD', 'Liberian Dollar', '\$'),
  Currency('LYD', 'Libyan Dinar', 'ل.د'),

  // M
  Currency('MOP', 'Macanese Pataca', 'P'),
  Currency('MKD', 'Macedonian Denar', 'ден'),
  Currency('MGA', 'Malagasy Ariary', 'Ar'),
  Currency('MWK', 'Malawian Kwacha', 'MK'),
  Currency('MYR', 'Malaysian Ringgit', 'RM'),
  Currency('MVR', 'Maldivian Rufiyaa', 'Rf'),
  Currency('MRU', 'Mauritanian Ouguiya', 'UM'),
  Currency('MUR', 'Mauritian Rupee', '₨'),
  Currency('MXN', 'Mexican Peso', '\$'),
  Currency('MDL', 'Moldovan Leu', 'L'),
  Currency('MNT', 'Mongolian Tögrög', '₮'),
  Currency('MAD', 'Moroccan Dirham', 'د.م.'),
  Currency('MZN', 'Mozambican Metical', 'MT'),

  // N
  Currency('NAD', 'Namibian Dollar', '\$'),
  Currency('NPR', 'Nepalese Rupee', '₨'),
  Currency('ANG', 'Netherlands Antillean Guilder', 'ƒ'),
  Currency('NZD', 'New Zealand Dollar', 'NZ\$'),
  Currency('NIO', 'Nicaraguan Córdoba', 'C\$'),
  Currency('NGN', 'Nigerian Naira', '₦'),
  Currency('KPW', 'North Korean Won', '₩'),
  Currency('NOK', 'Norwegian Krone', 'kr'),

  // O
  Currency('OMR', 'Omani Rial', 'ر.ع.'),

  // P
  Currency('PKR', 'Pakistani Rupee', '₨'),
  Currency('PAB', 'Panamanian Balboa', 'B/.'),
  Currency('PGK', 'Papua New Guinean Kina', 'K'),
  Currency('PYG', 'Paraguayan Guaraní', '₲'),
  Currency('PEN', 'Peruvian Sol', 'S/'),
  Currency('PHP', 'Philippine Peso', '₱'),
  Currency('PLN', 'Polish Złoty', 'zł'),

  // Q
  Currency('QAR', 'Qatari Riyal', 'ر.ق'),

  // R
  Currency('RON', 'Romanian Leu', 'lei'),
  Currency('RUB', 'Russian Ruble', '₽'),
  Currency('RWF', 'Rwandan Franc', 'FRw'),

  // S
  Currency('SAR', 'Saudi Riyal', 'ر.س'),
  Currency('RSD', 'Serbian Dinar', 'дин'),
  Currency('SCR', 'Seychellois Rupee', '₨'),
  Currency('SLL', 'Sierra Leonean Leone', 'Le'),
  Currency('SGD', 'Singapore Dollar', 'S\$'),
  Currency('SBD', 'Solomon Islands Dollar', '\$'),
  Currency('SOS', 'Somali Shilling', 'Sh'),
  Currency('ZAR', 'South African Rand', 'R'),
  Currency('KRW', 'South Korean Won', '₩'),
  Currency('LKR', 'Sri Lankan Rupee', '₨'),
  Currency('SDG', 'Sudanese Pound', 'ج.س.'),
  Currency('SRD', 'Surinamese Dollar', '\$'),
  Currency('SEK', 'Swedish Krona', 'kr'),
  Currency('CHF', 'Swiss Franc', 'CHF'),
  Currency('SYP', 'Syrian Pound', '£'),

  // T
  Currency('TWD', 'Taiwan Dollar', 'NT\$'),
  Currency('TJS', 'Tajikistani Somoni', 'ЅМ'),
  Currency('TZS', 'Tanzanian Shilling', 'TSh'),
  Currency('THB', 'Thai Baht', '฿'),
  Currency('TOP', 'Tongan Paʻanga', 'T\$'),
  Currency('TTD', 'Trinidad & Tobago Dollar', 'TT\$'),
  Currency('TND', 'Tunisian Dinar', 'د.ت'),
  Currency('TRY', 'Turkish Lira', '₺'),
  Currency('TMT', 'Turkmenistani Manat', 'm'),

  // U
  Currency('UGX', 'Ugandan Shilling', 'USh'),
  Currency('UAH', 'Ukrainian Hryvnia', '₴'),
  Currency('AED', 'UAE Dirham', 'د.إ'),
  Currency('GBP', 'British Pound', '£'),
  Currency('USD', 'US Dollar', '\$'),
  Currency('UYU', 'Uruguayan Peso', '\$'),
  Currency('UZS', 'Uzbekistani Som', 'soʻm'),

  // V
  Currency('VUV', 'Vanuatu Vatu', 'VT'),
  Currency('VES', 'Venezuelan Bolívar', 'Bs.'),
  Currency('VND', 'Vietnamese Dong', '₫'),

  // Y
  Currency('YER', 'Yemeni Rial', '﷼'),

  // Z
  Currency('ZMW', 'Zambian Kwacha', 'ZK'),
  Currency('ZWL', 'Zimbabwean Dollar', 'Z\$'),
];

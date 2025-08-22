import 'package:flutter/material.dart';

class Country {
  final String code;
  final String name;
  final String dial;
  final String flag;
  const Country(this.code, this.name, this.dial, this.flag);
}

const countries = <Country>[
  Country('AF','Afghanistan','+93','🇦🇫'),
  Country('IR','Iran','+98','🇮🇷'),
  Country('TR','Türkiye','+90','🇹🇷'),
  Country('PK','Pakistan','+92','🇵🇰'),
  Country('US','United States','+1','🇺🇸'),
  Country('DE','Deutschland','+49','🇩🇪'),
];

typedef OnPick = void Function(Country);

class CountryPickerField extends StatelessWidget {
  final Country value;
  final OnPick onPick;
  const CountryPickerField({super.key, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final sel = await showModalBottomSheet<Country>(
          context: context,
          builder: (_) => SafeArea(
            child: ListView(
              children: [
                for (final c in countries)
                  ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 20)),
                    title: Text('${c.name} (${c.dial})'),
                    onTap: ()=> Navigator.pop(context, c),
                  )
              ],
            ),
          ),
        );
        if (sel != null) onPick(sel);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.flag),
          const SizedBox(width: 6),
          Text(value.dial, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

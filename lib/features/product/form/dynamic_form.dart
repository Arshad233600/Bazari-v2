import 'package:flutter/material.dart';
import 'form_types.dart';

class DynamicProductForm extends StatefulWidget {
  const DynamicProductForm({
    super.key,
    required this.schema,
    this.initial,
    this.onChanged,
  });

  final CategorySchema schema;
  final Map<String, dynamic>? initial;
  final ValueChanged<Map<String, dynamic>>? onChanged;

  @override
  State<DynamicProductForm> createState() => _DynamicProductFormState();
}

class _DynamicProductFormState extends State<DynamicProductForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initial ?? {});
  }

  void _update(String key, dynamic value) {
    setState(() => _data[key] = value);
    widget.onChanged?.call(_data);
  }

  String? _reqValidator(FieldSpec f, String? v) {
    if (f.required && (v == null || v.trim().isEmpty)) {
      return 'این فیلد الزامی است';
    }
    return null;
  }

  String? _numValidator(FieldSpec f, String? v) {
    if (f.required && (v == null || v.trim().isEmpty)) {
      return 'این فیلد الزامی است';
    }
    if (v != null && v.trim().isNotEmpty) {
      final parsed = num.tryParse(v.replaceAll(',', '.'));
      if (parsed == null) return 'عدد نامعتبر';
      if (f.min != null && parsed < f.min!) return 'کمتر از حداقل (${f.min})';
      if (f.max != null && parsed > f.max!) return 'بیشتر از حداکثر (${f.max})';
    }
    return null;
  }

  Widget _buildField(FieldSpec f) {
    final value = _data[f.key];

    switch (f.type) {
      case FieldType.text:
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: f.label,
            hintText: f.hint,
          ),
          validator: (v) => _reqValidator(f, v),
          onChanged: (v) => _update(f.key, v),
        );

      case FieldType.number:
      case FieldType.integer:
        return TextFormField(
          initialValue: value?.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: f.label,
            hintText: f.hint,
            suffixText: f.unit,
          ),
          validator: (v) => _numValidator(f, v),
          onChanged: (v) {
            final parsed = num.tryParse(v.replaceAll(',', '.'));
            _update(f.key, parsed);
          },
        );

      case FieldType.select:
        final opts = f.options ?? const <String>[];
        return DropdownButtonFormField<String>(
          value: (value is String && opts.contains(value)) ? value : null,
          decoration: InputDecoration(labelText: f.label),
          items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => _update(f.key, v),
          validator: (v) => f.required && (v == null || v.isEmpty) ? 'انتخاب الزامی' : null,
        );

      case FieldType.multiselect:
        final opts = f.options ?? const <String>[];
        final selected = (value is List) ? List<String>.from(value) : <String>[];
        return _MultiSelectChips(
          label: f.label,
          options: opts,
          initial: selected,
          onChanged: (vals) => _update(f.key, vals),
        );

      case FieldType.toggle:
        final boolVal = value == true;
        return SwitchListTile(
          title: Text(f.label),
          value: boolVal,
          onChanged: (v) => _update(f.key, v),
        );

      case FieldType.repeater:
        final list = (value is List) ? List<String>.from(value) : <String>[];
        return _RepeaterString(
          label: f.label,
          hint: f.hint ?? 'مورد جدید…',
          values: list,
          onChanged: (vals) => _update(f.key, vals),
        );

      case FieldType.group:
        final Map<String, dynamic> groupData =
            (value is Map<String, dynamic>) ? value : <String, dynamic>{};
        return _GroupFields(
          label: f.label,
          fields: f.children ?? const <FieldSpec>[],
          data: groupData,
          onChanged: (m) => _update(f.key, m),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // کارت فرم
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: FormStyles.sectionPad,
            decoration: FormStyles.card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.schema.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...widget.schema.fields.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildField(f),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// مولتی‌سلکت چیپ‌ها
class _MultiSelectChips extends StatefulWidget {
  const _MultiSelectChips({
    required this.label,
    required this.options,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_MultiSelectChips> createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<_MultiSelectChips> {
  late List<String> _sel;
  @override
  void initState() { super.initState(); _sel = List<String>.from(widget.initial); }

  void _toggle(String v) {
    setState(() {
      if (_sel.contains(v)) {
        _sel.remove(v);
      } else {
        _sel.add(v);
      }
    });
    widget.onChanged(_sel);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: -6,
          children: widget.options.map((e) {
            final on = _sel.contains(e);
            return FilterChip(
              label: Text(e),
              selected: on,
              onSelected: (_) => _toggle(e),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// رپیتر لیست رشته‌ای (افزودن موردی)
class _RepeaterString extends StatefulWidget {
  const _RepeaterString({
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_RepeaterString> createState() => _RepeaterStringState();
}

class _RepeaterStringState extends State<_RepeaterString> {
  late List<String> _vals;
  final _ctrl = TextEditingController();

  @override
  void initState() { super.initState(); _vals = List<String>.from(widget.values); }

  void _add() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _vals.add(t));
    _ctrl.clear();
    widget.onChanged(_vals);
  }

  void _remove(int i) {
    setState(() => _vals.removeAt(i));
    widget.onChanged(_vals);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('افزودن')),
          ],
        ),
        const SizedBox(height: 8),
        ..._vals.asMap().entries.map((e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(e.value),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _remove(e.key),
                tooltip: 'حذف',
              ),
            )),
      ],
    );
  }
}

/// گروه داخلی از فیلدها (در صورت نیاز)
class _GroupFields extends StatelessWidget {
  const _GroupFields({
    required this.label,
    required this.fields,
    required this.data,
    required this.onChanged,
  });

  final String label;
  final List<FieldSpec> fields;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> local = Map<String, dynamic>.from(data);
    Widget buildField(FieldSpec f) {
      final v = local[f.key];
      switch (f.type) {
        case FieldType.text:
          return TextFormField(
            initialValue: v?.toString(),
            decoration: InputDecoration(labelText: f.label),
            onChanged: (t) { local[f.key] = t; onChanged(local); },
          );
        case FieldType.number:
        case FieldType.integer:
          return TextFormField(
            initialValue: v?.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: f.label, suffixText: f.unit),
            onChanged: (t) { local[f.key] = num.tryParse(t.replaceAll(',', '.')); onChanged(local); },
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...fields.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: buildField(f),
              )),
        ],
      ),
    );
  }
}

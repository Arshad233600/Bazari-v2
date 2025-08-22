import 'package:flutter/material.dart';
import '../models/product.dart';
import '../form/form_types.dart';
import '../form/dynamic_form.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    required this.categoryId,      // house / car / phone / job ...
    this.initialDetails,           // برای ویرایش
    this.onSubmit,                 // اگر بخواهی مستقیم ذخیره کنی
  });

  final String categoryId;
  final Map<String, dynamic>? initialDetails;
  final ValueChanged<Map<String, dynamic>>? onSubmit;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late CategorySchema _schema;
  Map<String, dynamic> _details = {};

  @override
  void initState() {
    super.initState();
    _schema = ProductSchemas.byId(widget.categoryId);
    _details = Map<String, dynamic>.from(widget.initialDetails ?? {});
  }

  void _save() {
    if (widget.onSubmit != null) widget.onSubmit!(_details);
    Navigator.of(context).pop<Map<String, dynamic>>(_details);
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('ثبت ${_schema.title}'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('ذخیره'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // توضیح کوتاه
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: th.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'فرم مطابق دسته «${_schema.title}» است. فیلدها را پر کنید.',
              style: th.textTheme.bodyMedium?.copyWith(color: th.colorScheme.onSecondaryContainer),
            ),
          ),
          DynamicProductForm(
            schema: _schema,
            initial: _details,
            onChanged: (d) => _details = d,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/object_controller.dart';
import '../../models/api_object.dart';
import '../../services/navigation_service.dart';
import 'widgets/loading_widget.dart';

class KeyValuePair {
  final TextEditingController keyController;
  final TextEditingController valueController;

  KeyValuePair({String? key, String? value})
    : keyController = TextEditingController(text: key ?? ''),
      valueController = TextEditingController(text: value ?? '');

  String get key => keyController.text;
  String get value => valueController.text;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class ObjectFormScreen extends StatefulWidget {
  const ObjectFormScreen({super.key});

  @override
  State<ObjectFormScreen> createState() => _ObjectFormScreenState();
}

class _ObjectFormScreenState extends State<ObjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isEditMode = false;
  String? _editingObjectId;

  List<KeyValuePair> _keyValuePairs = [KeyValuePair()];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final String? objectId = Get.parameters['id'];
    final ObjectController controller = Get.put(
      ObjectController(),
      permanent: false,
    );

    if (objectId != null && objectId.isNotEmpty) {
      _isEditMode = true;
      _editingObjectId = objectId;

      final existingObject = controller.selectedObject.value;
      if (existingObject != null && existingObject.id == objectId) {
        _populateForm(existingObject);
      } else {
        controller.getObjectById(objectId).then((object) {
          if (object != null) {
            _populateForm(object);
          }
        });
      }
    }
  }

  void _populateForm(ApiObject object) {
    _nameController.text = object.name;
    if (object.data != null && object.data!.isNotEmpty) {
      setState(() {
        _keyValuePairs = object.data!.entries
            .map(
              (entry) =>
                  KeyValuePair(key: entry.key, value: entry.value.toString()),
            )
            .toList();

        if (_keyValuePairs.isEmpty || _keyValuePairs.last.key.isNotEmpty) {
          _keyValuePairs.add(KeyValuePair());
        }
      });
    }
  }

  Map<String, dynamic> _buildDataFromKeyValuePairs() {
    final Map<String, dynamic> data = {};

    for (final pair in _keyValuePairs) {
      if (pair.key.trim().isNotEmpty && pair.value.trim().isNotEmpty) {
        final String value = pair.value.trim();
        if (RegExp(r'^\d+$').hasMatch(value)) {
          data[pair.key.trim()] = int.tryParse(value) ?? value;
        } else if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
          data[pair.key.trim()] = double.tryParse(value) ?? value;
        } else if (value.toLowerCase() == 'true') {
          data[pair.key.trim()] = true;
        } else if (value.toLowerCase() == 'false') {
          data[pair.key.trim()] = false;
        } else {
          data[pair.key.trim()] = value;
        }
      }
    }

    return data;
  }

  void _addNewKeyValuePair() {
    setState(() {
      _keyValuePairs.add(KeyValuePair());
    });
  }

  void _removeKeyValuePair(int index) {
    if (_keyValuePairs.length > 1) {
      setState(() {
        _keyValuePairs[index].dispose();
        _keyValuePairs.removeAt(index);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool hasValidData = false;
    for (final pair in _keyValuePairs) {
      if (pair.key.trim().isNotEmpty && pair.value.trim().isNotEmpty) {
        hasValidData = true;
        break;
      }
    }

    final ObjectController controller = Get.put(
      ObjectController(),
      permanent: false,
    );

    final Map<String, dynamic>? data = hasValidData
        ? _buildDataFromKeyValuePairs()
        : null;

    final ApiObject object = ApiObject(
      name: _nameController.text.trim(),
      data: data,
    );

    if (_isEditMode && _editingObjectId != null) {
      await controller.updateObject(_editingObjectId!, object);
    } else {
      await controller.createObject(object);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final pair in _keyValuePairs) {
      pair.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Object' : 'Create Object'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          GetBuilder<ObjectController>(
            builder: (controller) => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _submitForm,
                    child: Text(_isEditMode ? 'Update' : 'Create'),
                  ),
          ),
        ],
      ),
      body: GetBuilder<ObjectController>(
        builder: (controller) {
          if (_isEditMode &&
              controller.isLoading.value &&
              controller.selectedObject.value?.id != _editingObjectId) {
            return const LoadingWidget(message: 'Loading object data...');
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Object Name',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter object name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters long';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.data_object,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Object Data',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add key-value pairs to define the object properties. Leave empty if no data is needed.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 16),

                          ...List.generate(_keyValuePairs.length, (index) {
                            final pair = _keyValuePairs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: pair.keyController,
                                      decoration: InputDecoration(
                                        hintText: 'Key (e.g., color)',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.key),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        if (index ==
                                                _keyValuePairs.length - 1 &&
                                            value.isNotEmpty &&
                                            _keyValuePairs.length < 10) {
                                          _addNewKeyValuePair();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: pair.valueController,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Value (e.g., red, 128, true)',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.edit),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                    ),
                                  ),

                                  if (_keyValuePairs.length > 1)
                                    IconButton(
                                      onPressed: () =>
                                          _removeKeyValuePair(index),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      color: Colors.red,
                                      tooltip: 'Remove this field',
                                    )
                                  else
                                    const SizedBox(width: 48),
                                ],
                              ),
                            );
                          }),

                          if (_keyValuePairs.length < 10)
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _addNewKeyValuePair,
                                icon: const Icon(Icons.add),
                                label: const Text('Add New Field'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: GetBuilder<ObjectController>(
                      builder: (controller) => FilledButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : _submitForm,
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_isEditMode ? Icons.update : Icons.add),
                        label: Text(
                          controller.isLoading.value
                              ? (_isEditMode ? 'Updating...' : 'Creating...')
                              : (_isEditMode
                                    ? 'Update Object'
                                    : 'Create Object'),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Data Format Help',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Examples of key-value pairs:',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• color → red',
                                  style: _helpTextStyle(context),
                                ),
                                Text(
                                  '• capacity → 256',
                                  style: _helpTextStyle(context),
                                ),
                                Text(
                                  '• price → 999.99',
                                  style: _helpTextStyle(context),
                                ),
                                Text(
                                  '• available → true',
                                  style: _helpTextStyle(context),
                                ),
                                Text(
                                  '• brand → Apple',
                                  style: _helpTextStyle(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Values are automatically converted to numbers or booleans when possible.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  TextStyle _helpTextStyle(BuildContext context) {
    return const TextStyle(fontFamily: 'monospace', fontSize: 12);
  }
}

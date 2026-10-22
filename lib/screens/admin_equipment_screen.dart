import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class AdminEquipmentScreen extends StatelessWidget {
  const AdminEquipmentScreen({super.key});

  Future<void> _showEquipmentDialog(
      BuildContext context, {
        String? equipmentId,
        Map<String, dynamic>? existingData,
      }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: existingData?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingData?['description']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: existingData?['category']?.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: existingData?['quantity']?.toString() ?? '',
    );

    final isEditing = equipmentId != null;
    final currentImageUrl =
        existingData?['imageUrl']?.toString() ?? '';

    Uint8List? selectedImageBytes;
    String? selectedImageName;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool isSaving = false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Equipment' : 'Add Equipment',
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatefulBuilder(
                          builder: (context, setImageState) {
                            return Column(
                              children: [
                                if (selectedImageBytes != null)
                                  Image.memory(
                                    selectedImageBytes!,
                                    height: 130,
                                    width: 180,
                                    fit: BoxFit.contain,
                                  )
                                else if (currentImageUrl.isNotEmpty)
                                  Image.network(
                                    currentImageUrl,
                                    height: 130,
                                    width: 180,
                                    fit: BoxFit.contain,
                                    errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                        ) {
                                      return const Icon(
                                        Icons.broken_image_outlined,
                                        size: 60,
                                      );
                                    },
                                  )
                                else
                                  const Icon(
                                    Icons.image_outlined,
                                    size: 60,
                                  ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: const Text(
                                    'Choose Equipment Image',
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                    try {
                                      final picker =
                                      ImagePicker();

                                      final file =
                                      await picker.pickImage(
                                        source:
                                        ImageSource.gallery,
                                        imageQuality: 80,
                                      );

                                      if (file == null) return;

                                      final bytes =
                                      await file.readAsBytes();

                                      setImageState(() {
                                        selectedImageBytes =
                                            bytes;
                                        selectedImageName =
                                            file.name;
                                      });
                                    } catch (e) {
                                      if (!dialogContext.mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not select image: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Equipment Name',
                          ),
                          validator: (value) =>
                          value == null ||
                              value.trim().isEmpty
                              ? 'Enter an equipment name.'
                              : null,
                        ),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: (value) =>
                          value == null ||
                              value.trim().isEmpty
                              ? 'Enter a description.'
                              : null,
                        ),
                        TextFormField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          validator: (value) =>
                          value == null ||
                              value.trim().isEmpty
                              ? 'Enter a category.'
                              : null,
                        ),
                        TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                          validator: (value) {
                            final quantity =
                            int.tryParse(value ?? '');

                            if (quantity == null || quantity < 0) {
                              return 'Enter a valid quantity.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                      });

                      final quantity = int.parse(
                        quantityController.text.trim(),
                      );

                      final data = <String, dynamic>{
                        'name': nameController.text.trim(),
                        'description':
                        descriptionController.text.trim(),
                        'category':
                        categoryController.text.trim(),
                        'quantity': quantity,
                        'isAvailable': quantity > 0,
                        'imageUrl': currentImageUrl,
                      };

                      try {
                        // Upload a newly selected image first.
                        if (selectedImageBytes != null) {
                          data['imageUrl'] =
                          await CloudinaryService
                              .uploadEquipmentImage(
                            selectedImageBytes!,
                            selectedImageName ??
                                'equipment_image.jpg',
                          );
                        }

                        final collection =
                        FirebaseFirestore.instance
                            .collection('equipment');

                        if (isEditing) {
                          await collection
                              .doc(equipmentId)
                              .update(data);
                        } else {
                          await collection.add(data);
                        }

                        if (!dialogContext.mounted) return;

                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Equipment updated successfully.'
                                  : 'Equipment added successfully.',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) return;

                        setDialogState(() {
                          isSaving = false;
                        });

                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to save equipment: $e',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isSaving ? 'Saving...' : 'Save',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      categoryController.dispose();
      quantityController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Equipment'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEquipmentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('equipment')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load equipment.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final equipment = snapshot.data!.docs;

          if (equipment.isEmpty) {
            return const Center(
              child: Text('No equipment found.'),
            );
          }

          return ListView.builder(
            itemCount: equipment.length,
            itemBuilder: (context, index) {
              final document = equipment[index];
              final item = document.data();
              final quantity = item['quantity'] ?? 0;
              final imageUrl =
                  item['imageUrl']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 32,
                    ),
                  )
                      : const Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                  ),
                  title: Text(
                    item['name']?.toString() ??
                        'Unnamed equipment',
                  ),
                  subtitle: Text(
                    'Category: ${item['category'] ?? 'N/A'}\n'
                        'Quantity: $quantity',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Equipment',
                    onPressed: () => _showEquipmentDialog(
                      context,
                      equipmentId: document.id,
                      existingData: item,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

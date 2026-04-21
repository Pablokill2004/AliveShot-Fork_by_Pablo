import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfilePage({super.key, required this.initialData});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthdayController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  late TextEditingController _profileImageController;
  late TextEditingController _bannerImageController;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'I prefer not to say'];

  File? _profileImageFile;
  File? _bannerImageFile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData['name'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.initialData['last_name'] ?? '',
    );
    _birthdayController = TextEditingController(
      text: widget.initialData['birthday'] ?? '',
    );
    _titleController = TextEditingController(
      text: widget.initialData['title'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.initialData['bio'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialData['address'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialData['phone'] ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.initialData['username'] ?? '',
    );
    _profileImageController = TextEditingController(
      text: widget.initialData['image'] ?? '',
    );
    _bannerImageController = TextEditingController(
      text: widget.initialData['image_header'] ?? '',
    );

    _selectedGender = widget.initialData['gender'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _profileImageController.dispose();
    _bannerImageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String type) async {
    final storageRef = firebase_storage.FirebaseStorage.instance.ref(
      'user_images/${DateTime.now().millisecondsSinceEpoch}_$type.jpg',
    );
    try {
      // Debug log: starting upload
      if (kDebugMode) {
        // ignore: avoid_print
        print('Starting upload for $type -> ${imageFile.path}');
      }
      final uploadTask = storageRef.putFile(imageFile);
      await uploadTask.whenComplete(() {});
      final downloadUrl = await storageRef.getDownloadURL();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Upload complete for $type. URL: $downloadUrl');
      }
      return downloadUrl;
    } on firebase_storage.FirebaseException catch (e) {
      if (!mounted) return null;
      // Provide actionable message for App Check issues
      String message = 'Error al subir la imagen: ${e.message ?? e.code}';
      if (e.message != null && e.message!.toLowerCase().contains('app check')) {
        message +=
            '\nPista: verifica que Firebase App Check esté habilitado y que el token debug esté registrado en la consola.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'Firebase Storage exception during upload: ${e.code} ${e.message}',
        );
      }
      return null;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir la imagen: $e')));
      if (kDebugMode) {
        // ignore: avoid_print
        print('Unknown error during upload: $e');
      }
      return null;
    }
  }

  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (type == 'profile') {
          _profileImageFile = File(pickedFile.path);
        } else if (type == 'banner') {
          _bannerImageFile = File(pickedFile.path);
        }
      });
      final url = await _uploadImage(File(pickedFile.path), type);
      if (url != null) {
        setState(() {
          if (type == 'profile') {
            _profileImageController.text = url;
          } else if (type == 'banner') {
            _bannerImageController.text = url;
            // Prefer the uploaded network image after successful upload
            _bannerImageFile = null;
          }
        });
      }
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'name': _nameController.text,
        'last_name': _lastNameController.text,
        'birthday': _birthdayController.text,
        'gender': _selectedGender,
        'title': _titleController.text,
        'bio': _bioController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'username': _usernameController.text,
        'image': _profileImageController.text,
        'image_header': _bannerImageController.text,
      };

      debugPrint('Datos actualizados: $updatedData');
      Navigator.pop(context, updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),

        //color de texto
        actions: [
          IconButton(
            color: colorScheme.onPrimary,
            icon: const Icon(Icons.save, size: 24),
            onPressed: _saveForm,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.secondary, // gradiente
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Image
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: _bannerImageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_bannerImageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_bannerImageController.text.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              _bannerImageController.text,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage(
                                            // Fondo por defecto si no hay imagen
                                            image: AssetImage(
                                              'images/defaultBanner.png',
                                            ),
                                            fit: BoxFit.cover,
                                          )),
                            ),
                            child:
                                (_bannerImageFile == null &&
                                    _bannerImageController.text.isEmpty)
                                ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: colorScheme.onPrimary,
                              ),
                              onPressed: () => _pickImage('banner'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Imagen de portada',
                        style: TextStyle(
                          color: textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Image
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImageFile != null
                                  ? Image.file(
                                      _profileImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : (_profileImageController.text.isNotEmpty
                                        ? Image.network(
                                            _profileImageController.text,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          )),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: colorScheme.onPrimary,
                              ),
                              onPressed: () => _pickImage('profile'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Foto de perfil',
                        style: TextStyle(
                          color: textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildFormField(
                  controller: _nameController,
                  label: 'Nombre',

                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _lastNameController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _birthdayController,
                  label: 'Fecha de nacimiento',
                  icon: Icons.cake,
                  isReadOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona tu fecha de nacimiento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _titleController,
                  label: 'Título profesional',
                  icon: Icons.work_outline,
                  maxLength: 255,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _bioController,
                  label: 'Biografía',
                  icon: Icons.description,
                  maxLines: 3,
                  maxLength: 255,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _addressController,
                  label: 'Dirección',
                  icon: Icons.location_on_outlined,
                  maxLength: 255,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 255,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _usernameController,
                  label: 'Nombre de usuario',
                  icon: Icons.alternate_email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre de usuario';
                    }
                    if (value.contains(' ')) {
                      return 'El nombre de usuario no puede contener espacios';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        color: textTheme.bodySmall?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isReadOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    int? maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onPrimary),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onPrimary, width: 1.5),
        ),
        prefixIcon: Icon(icon, color: colorScheme.onPrimary), // Ícono dinámico
        suffixIcon: isReadOnly
            ? IconButton(
                icon: Icon(Icons.calendar_today, color: colorScheme.onPrimary),
                onPressed: onTap,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterStyle: TextStyle(color: colorScheme.onPrimary),
      ),
      style: TextStyle(color: colorScheme.onPrimary), // Texto dinámico
      cursorColor: colorScheme.onPrimary,
      readOnly: isReadOnly,
      onTap: onTap,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdownField() {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      //initialValue: _selectedGender,
      initialValue: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Género',
        labelStyle: TextStyle(color: colorScheme.onPrimary),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onPrimary, width: 1.5),
        ),
        prefixIcon: Icon(
          Icons.transgender,
          color: colorScheme.onPrimary, // Ícono dinámico
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: colorScheme.surface, // Fondo del menú desplegable
      style: TextStyle(color: colorScheme.onSurface), // Texto dinámico
      icon: Icon(
        Icons.arrow_drop_down,
        color: colorScheme.onPrimary, // Ícono dinámico
      ),
      items: _genders.map((String gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender, style: TextStyle(color: colorScheme.onPrimary)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona tu género';
        }
        return null;
      },
    );
  }
}

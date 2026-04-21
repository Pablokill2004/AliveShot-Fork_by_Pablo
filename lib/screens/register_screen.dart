import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_services/api_service.dart';

import 'package:alive_shot/screens/pages/pages.dart';
import '../services/email_verification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Controladores para datos personales
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  String? _gender;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();

  // Lista de campos a completar en modals
  final List<Map<String, dynamic>> _personalFields = [
    {
      'label': 'Nombre',
      'controller': null,
      'type': 'text',
      'icon': Icons.person,
      'required': true,
    },
    {
      'label': 'Apellido',
      'controller': null,
      'type': 'text',
      'icon': Icons.person_outline,
      'required': true,
    },
    {
      'label': 'Fecha de Nacimiento',
      'controller': null,
      'type': 'date',
      'icon': Icons.cake,
      'required': true,
    },
    {
      'label': 'Género',
      'controller': null,
      'type': 'dropdown',
      'icon': Icons.transgender,
      'required': true,
    },
    {
      'label': 'Dirección',
      'controller': null,
      'type': 'text',
      'icon': Icons.home,
      'required': false,
    },
    {
      'label': 'Teléfono',
      'controller': null,
      'type': 'text',
      'icon': Icons.phone,
      'required': false,
    },
    {
      'label': 'Título',
      'controller': null,
      'type': 'text',
      'icon': Icons.work,
      'required': false,
    },
    {
      'label': 'Biografía',
      'controller': null,
      'type': 'text',
      'icon': Icons.description,
      'required': false,
    },
    {
      'label': 'Username',
      'controller': null,
      'type': 'text',
      'icon': Icons.person,
      'required': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _personalFields[0]['controller'] = _nameController;
    _personalFields[1]['controller'] = _lastNameController;
    _personalFields[2]['controller'] = _birthdayController;
    _personalFields[4]['controller'] = _addressController;
    _personalFields[5]['controller'] = _phoneController;
    _personalFields[6]['controller'] = _titleController;
    _personalFields[7]['controller'] = _bioController;
    _personalFields[8]['controller'] = _usernameController;
    _clearGoogleSignIn();

    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _clearGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Error al limpiar sesión de GoogleSignIn: $e');
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Validar formato de email
      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text)) {
        throw Exception('invalid-email');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await EmailVerificationService.sendVerificationEmail(
        userCredential.user!,
      );
      if (!mounted) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se ha enviado un correo de verificación. Verifícalo antes de continuar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Esperar verificación
      await EmailVerificationService.waitForEmailVerification(
        userCredential.user!,
      );
      await _showPersonalDataModals(userCredential.user!);
    } catch (e) {
      String errorMessage = 'Error al registrar: $e';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'El email ya está registrado. Intenta con otro.';
            break;
          case 'invalid-email':
            errorMessage = 'El email es inválido. Verifica el formato.';
            break;
          case 'weak-password':
            errorMessage = 'La contraseña es débil. Usa al menos 6 caracteres.';
            break;
          case 'network-request-failed':
            errorMessage = 'Error de conexión. Verifica tu internet.';
            break;
          default:
            errorMessage = 'Error al registrar. Intenta nuevamente.';
        }
      }
      if (!mounted) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _clearGoogleSignIn();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (!mounted) return;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro con Google cancelado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _emailController.text = googleUser.email;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      // Enviar correo de verificación incluso para Google
      if (!userCredential.user!.emailVerified) {
        await EmailVerificationService.sendVerificationEmail(
          userCredential.user!,
        );
        if (!mounted) return;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha enviado un correo de verificación. Verifícalo antes de continuar.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await EmailVerificationService.waitForEmailVerification(
          userCredential.user!,
        );
      }
      await _showPersonalDataModals(userCredential.user!);
    } catch (e) {
      String errorMessage = 'Error al registrar con Google: $e';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage =
                'La cuenta ya existe con otro proveedor. Usa el mismo método.';
            break;
          case 'network-request-failed':
            errorMessage = 'Error de conexión. Verifica tu internet.';
            break;
          default:
            errorMessage = 'Error al registrar con Google. Intenta nuevamente.';
        }
      }
      if (!mounted) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showPersonalDataModals(User user) async {
    // ignore: unused_local_variable
    for (var field in _personalFields) {
      bool completed = false;
      while (!completed) {
        // Llamar directamente al formulario único
        await _showPersonalDataForm(user);

        // Sincronizar los datos del usuario con la base de datos
        await _syncUserToDb(user);

        // Redirigir al usuario a la página principal o de bienvenida
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashPage()),
        );
      }
    }
    await _syncUserToDb(user);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashPage()),
    );
  }

  Future<void> _showPersonalDataForm(User user) async {
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completa tu información personal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Nombre
                          TextFormField(
                            controller: _nameController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Apellido
                          TextFormField(
                            controller: _lastNameController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu apellido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Fecha de nacimiento
                          TextFormField(
                            controller: _birthdayController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Fecha de Nacimiento',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                _birthdayController.text = '${date.toLocal()}'
                                    .split(' ')[0];
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, selecciona tu fecha de nacimiento';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Género
                          DropdownButtonFormField<String>(
                            //initialValue: _gender,
                            initialValue: _gender,
                            decoration: InputDecoration(
                              labelText: 'Género',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Male',
                                child: Text(
                                  'Masculino',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Female',
                                child: Text(
                                  'Femenino',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'I prefer not to say',
                                child: Text(
                                  'Prefiero no decir',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _gender = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, selecciona tu género';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Dirección
                          TextFormField(
                            controller: _addressController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Dirección',
                              filled: true,
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Teléfono
                          TextFormField(
                            controller: _phoneController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Teléfono',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Título
                          TextFormField(
                            controller: _titleController,
                              cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Título',
                              filled: true,
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Biografía
                          TextFormField(
                            controller: _bioController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Biografía',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            cursorColor: colorScheme.onPrimary,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimary,
                              ),
                              filled: true,
                                  fillColor: colorScheme.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await _syncUserToDb(user);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashPage()),
    );
  }

  Future<void> _syncUserToDb(User user) async {
    try {
      await ApiService.createOrUpdateUser(
        user.uid,
        email: user.email ?? _emailController.text,
        name: _nameController.text,
        lastname: _lastNameController.text,
        birthday: _birthdayController.text,
        gender: _gender,
        address: _addressController.text,
        phone: _phoneController.text,
        title: _titleController.text,
        bio: _bioController.text,
        username: _usernameController.text,
      );
      if (!mounted) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = 'Error al registrar en la base de datos: $e';
      if (e.toString().contains('404')) {
        errorMessage = 'Usuario no encontrado. Verifica tus credenciales.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Error en el servidor. Intenta nuevamente más tarde.';
      } else if (e.toString().contains('unique')) {
        errorMessage = 'El username ya existe. Elige otro.';
      } else if (e.toString().contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : SizedBox.expand(
              // Asegura que el fondo ocupe toda la pantalla
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.deepPurple.shade700,
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade300,
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Logo y título
                          Column(
                            children: [
                              const Icon(
                                Icons.people_alt_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'AliveShot',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Únete a nuestra comunidad',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Formulario
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: colorScheme.onPrimary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    // ignore: deprecated_member_use
                                  fillColor: colorScheme.surfaceContainer,
                                    // ignore: deprecated_member_use
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: colorScheme.onPrimary,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  cursorColor: colorScheme.onPrimary,
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle: TextStyle(
                                      color: colorScheme.onPrimary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    // ignore: deprecated_member_use
                                  fillColor: colorScheme.surfaceContainer,
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _registerWithEmailAndPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.secondary,
                                      foregroundColor: colorScheme.onSecondary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: const Text(
                                      'Registrarse',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: Colors.grey),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'O continúa con',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _registerWithGoogle,
                                    icon: const Icon(
                                      Icons.g_mobiledata,
                                      size: 24,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      'Iniciar con Google',
                                      style: TextStyle(
                                        color: colorScheme.onSecondary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                        color: colorScheme.onSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Enlace a login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Ya tienes una cuenta? ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  );
                                },
                                child: const Text(
                                  'Inicia sesión',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

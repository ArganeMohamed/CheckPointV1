import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomeScreen.dart';
import 'SignUp.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;

  const LoginScreen({Key? key, this.prefilledEmail}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;



  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null) {
      _emailController.text = widget.prefilledEmail!;
    }
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un email';
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }



  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Attempt to sign in with Firebase Auth
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (userCredential.user != null) {
          // Store the current login timestamp in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastLogin', DateTime.now().millisecondsSinceEpoch);

          // Check if email is verified
          if (userCredential.user!.emailVerified) {
            // Email is verified, login successful
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connexion réussie')),
            );
            // Navigate to home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            // Email not verified, prompt user to verify email
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Veuillez vérifier votre e-mail avant de continuer.')),
            );
            // Sign out to prevent logged-in state with unverified email
            FirebaseAuth.instance.signOut();
          }
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase Auth errors
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'Aucun utilisateur trouvé avec cet email.';
            break;
          case 'wrong-password':
            message = 'Mot de passe incorrect.';
            break;
          case 'user-disabled':
            message = 'Ce compte a été désactivé.';
            break;
          case 'too-many-requests':
            message = 'Trop de tentatives. Veuillez réessayer plus tard.';
            break;
          default:
            message = 'Une erreur est survenue. Veuillez réessayer.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de réinitialisation envoyé')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image with gradient overlay
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/Header.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: emailValidator,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          suffixIcon: GestureDetector(
                            onTapDown: (_) {
                              setState(() {
                                _obscurePassword = false;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _obscurePassword = true;
                              });
                            },
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: passwordValidator,
                      ),
                      SizedBox(height: 15),
                      if (_isLoading)
                        CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Se connecter'),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpScreen()),
                          );
                        },
                        child: Text('Créer un compte'),
                      ),
                      TextButton(
                        onPressed: _resetPassword,
                        child: Text('Mot de passe oublié ?'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
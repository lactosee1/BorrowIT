import 'package:flutter/material.dart';
import 'equipment_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BorrowIT'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to BorrowIT!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Borrow school equipment with ease.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Login'),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Create Student Account'),
                ),
              ),

              const SizedBox(height: 12),
            ],

          ),
        ),
      ),
    );
  }
}
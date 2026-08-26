import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('개인정보처리방침 (구현 예정)'))
    );
  }
}
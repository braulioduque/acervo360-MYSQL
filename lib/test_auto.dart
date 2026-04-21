import 'package:flutter/material.dart';

class TestAc extends StatelessWidget {
  const TestAc({super.key});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (text) async {
        return ['a', 'b'];
      }
    );
  }
}

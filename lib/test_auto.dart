import 'package:flutter/material.dart';

class TestAc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (text) async {
        return ['a', 'b'];
      }
    );
  }
}

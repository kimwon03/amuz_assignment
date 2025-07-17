import 'package:flutter/material.dart';

import 'local_widgets/index.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: ConnectButton(),),
    );
  }
}

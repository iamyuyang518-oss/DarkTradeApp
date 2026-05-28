import 'package:flutter/material.dart';

class TradeExecutionWidget extends StatefulWidget {
  const TradeExecutionWidget({super.key});

  static const String routeName = 'TradeExecution';
  static const String routePath = '/tradeExecution';

  @override
  State<TradeExecutionWidget> createState() => _TradeExecutionWidgetState();
}

class _TradeExecutionWidgetState extends State<TradeExecutionWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade execution')),
      body: const Center(
        child: Text('Replace this screen with your trade flow.'),
      ),
    );
  }
}

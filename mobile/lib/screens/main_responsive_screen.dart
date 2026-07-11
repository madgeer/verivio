import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/phone_simulator.dart';
import 'desktop_dashboard.dart';

class MainResponsiveScreen extends StatefulWidget {
  const MainResponsiveScreen({super.key});

  @override
  State<MainResponsiveScreen> createState() => _MainResponsiveScreenState();
}

class _MainResponsiveScreenState extends State<MainResponsiveScreen> {
  late AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState();
    _state.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050314),
              Color(0xFF0F0C24),
              Color(0xFF140D30),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: isDesktop
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column: The Simulated iPhone
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: PhoneSimulator(state: _state, embedInFrame: true),
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Right Column: The Expanded Analytics Dashboard
                        Expanded(
                          flex: 7,
                          child: DesktopDashboard(state: _state),
                        ),
                      ],
                    ),
                  )
                : PhoneSimulator(state: _state, embedInFrame: false),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:wegather_app/containers/liquid_container.dart';
import 'package:wegather_app/containers/liquid_container_with_dilate.dart';

class LiquidScreen extends StatefulWidget {
  const LiquidScreen({super.key});

  @override
  State<LiquidScreen> createState() => _LiquidScreenState();
}

class _LiquidScreenState extends State<LiquidScreen> {
  Offset _containerPosition = const Offset(16, 200); // Initial position

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Static content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: LiquidContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Berk\'s Current Attempt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: LiquidGlass(
                    settings: const LiquidGlassSettings(
                      blur: 4,
                      thickness: 5,
                      glassColor: Color.fromARGB(1, 255, 255, 255),
                      ambientStrength: 0.5,
                      chromaticAberration: 2,
                    ),
                    shape: LiquidRoundedSuperellipse(borderRadius: Radius.circular(15.85), side: BorderSide(color: Colors.white, width: 1)),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(

                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color.fromARGB(60, 255, 255, 255), width: 1, ),
                          borderRadius: BorderRadius.circular(15.85),
                        ),
                        child: Text(
                          'Berk\'s Attempt with LG renderer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Movable container
          Positioned(
            left: _containerPosition.dx,
            top: _containerPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _containerPosition += details.delta;
                  
                  // Keep the container within screen bounds
                  final screenSize = MediaQuery.of(context).size;
                  final containerWidth = screenSize.width - 32;
                  const containerHeight = 60.0;
                  
                  _containerPosition = Offset(
                    _containerPosition.dx.clamp(0, screenSize.width - containerWidth),
                    _containerPosition.dy.clamp(0, screenSize.height - containerHeight - 80), // Account for status bar
                  );
                });
              },
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: LiquidContainerWithDilate(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Berk\'s Current Attempt With Dilate',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],


      ),
    );
  }
}

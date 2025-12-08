import '../utils/custom_widgets/loading_with_percentage.dart';
import 'package:flutter/material.dart';

/// Test widget to simulate the loading progress without generating video
class LoadingProgressTestScreen extends StatefulWidget {
  const LoadingProgressTestScreen({super.key});

  @override
  State<LoadingProgressTestScreen> createState() => _LoadingProgressTestScreenState();
}

class _LoadingProgressTestScreenState extends State<LoadingProgressTestScreen> {
  int _currentProgress = 0;
  bool _isLoading = false;

  void _startSimulation() {
    setState(() {
      _isLoading = true;
      _currentProgress = 0;
    });

    LoadingProgressDialog.show(
      context,
      percentage: _currentProgress,
      message1: 'Processing... ($_currentProgress%)',
      message2: 'Your result is on the way, just a few minutes to go',
    );

    _simulateProgress();
  }

  void _simulateProgress() {
    Future.delayed(const Duration(seconds: 3), () async{
      if (_currentProgress < 100 && _isLoading) {
        if(_currentProgress == 50){
          await Future.delayed(Duration(seconds: 10));
        }
        setState(() {
          _currentProgress += 5;
        });
        LoadingProgressDialog.update(
          context,
          _currentProgress,
          message1: 'Processing... ($_currentProgress%)',
          message2: 'Your result is on the way, just a few minutes to go',
        );

        _simulateProgress();
      } else if (_currentProgress >= 100) {
        Future.delayed(const Duration(seconds: 1), () {
          LoadingProgressDialog.hide(context);
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading Complete! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        });
      }
    });
  }

  void _stopSimulation() {
    setState(() {
      _isLoading = false;
    });
    LoadingProgressDialog.hide(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Progress Test'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.science,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Test Loading Animation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No credits will be consumed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      'Current Progress: $_currentProgress%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _currentProgress / 100,
                      backgroundColor: Colors.grey[300],
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startSimulation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Simulation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading ? _stopSimulation : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Test Buttons
            const Divider(height: 40),
            const Text(
              'Quick Test at Specific %',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickTestButton(10),
                _buildQuickTestButton(25),
                _buildQuickTestButton(50),
                _buildQuickTestButton(75),
                _buildQuickTestButton(90),
                _buildQuickTestButton(100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(int percentage) {
    return ElevatedButton(
      onPressed: () {
        LoadingProgressDialog.show(
          context,
          percentage: percentage,
          message1: 'Processing... ($percentage%)',
          message2: 'Testing at $percentage% progress',
        );

        // Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            LoadingProgressDialog.hide(context);
          }
        });
      },
      child: Text('$percentage%'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[100],
        foregroundColor: Colors.purple[900],
      ),
    );
  }
}
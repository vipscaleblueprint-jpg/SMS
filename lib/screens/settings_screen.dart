import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sim1Enabled = true;
  bool _sim2Enabled = false;
  bool _showInfoPopup = false;
  final GlobalKey _infoButtonKey = GlobalKey();

  void _toggleInfoPopup() {
    setState(() {
      _showInfoPopup = !_showInfoPopup;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MULTI SIM SETTINGS Header
                const Text(
                  'MULTI SIM SETTINGS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Antispam Limits Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ANTISPAM LIMITS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            key: _infoButtonKey,
                            onTap: _toggleInfoPopup,
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '2,000 SMS / DAY',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // SIM 1
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIM 1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '09123456789',
                            style: TextStyle(
                              fontSize: 14,
                              color: _sim1Enabled
                                  ? const Color(0xFFFBB03B)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _sim1Enabled,
                        onChanged: (value) {
                          setState(() {
                            _sim1Enabled = value;
                          });
                        },
                        activeColor: const Color(0xFFFBB03B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SIM 2
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIM 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '09123456789',
                            style: TextStyle(
                              fontSize: 14,
                              color: _sim2Enabled
                                  ? const Color(0xFFFBB03B)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _sim2Enabled,
                        onChanged: (value) {
                          setState(() {
                            _sim2Enabled = value;
                          });
                        },
                        activeColor: const Color(0xFFFBB03B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info Popup Overlay
          if (_showInfoPopup)
            GestureDetector(
              onTap: _toggleInfoPopup,
              child: Container(
                color: Colors.black26,
                child: Stack(
                  children: [
                    Positioned(
                      top: 140, // Adjust based on the info button position
                      left: 140, // Position popup from the info icon
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            ' Instructions\nInstructions Instructions\nInstructions Instructions\nInstructions IInstructionsnstructions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

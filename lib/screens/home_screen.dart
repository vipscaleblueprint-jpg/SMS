import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import '../services/sms_service.dart';
import '../widgets/compose_sms_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsService _smsService = SmsService();
  bool _permissionsGranted = false;
  List<SmsMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSms();
  }

  Future<void> _initSms() async {
    setState(() => _isLoading = true);
    final granted = await _smsService.requestPermissions();
    setState(() {
      _permissionsGranted = granted ?? false;
    });

    if (_permissionsGranted) {
      await _loadMessages();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMessages() async {
    final messages = await _smsService.getInboxMessages();
    setState(() {
      _messages = messages;
    });
  }

  Future<void> _sendMessage(String address, String message) async {
    await _smsService.sendSms(address: address, message: message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('SMS Sent!')));
    // Refresh messages just in case (though sent messages go to Sent box usually)
    // _loadMessages(); // Optional
  }

  void _showComposeSheet() {
    if (!_permissionsGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permissions not granted')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ComposeSmsSheet(onSend: _sendMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _permissionsGranted ? _loadMessages : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComposeSheet,
        icon: const Icon(Icons.send),
        label: const Text('Compose'),
      ),
    );
  }

  Widget _buildBody() {
    if (!_permissionsGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_failed, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'SMS permissions denied',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initSms,
              child: const Text('Retry Permissions'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No SMS messages found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: const Icon(Icons.person),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            title: Text(
              message.address ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.body ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateTime.fromMillisecondsSinceEpoch(
                        message.date!,
                      ).toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

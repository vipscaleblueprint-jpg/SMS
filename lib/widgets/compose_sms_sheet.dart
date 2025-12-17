import 'package:flutter/material.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;
  final int numberLength; // Fixed length for simplicity or min length

  const Country(this.name, this.code, this.dialCode, this.numberLength);
}

const List<Country> countries = [
  Country('Philippines', 'PH', '+63', 10), // e.g. 912 345 6789
  Country('Germany', 'DE', '+49', 11), // varies, avg 10-11
  Country('France', 'FR', '+33', 9),
  Country('Spain', 'ES', '+34', 9),
  Country('United Kingdom', 'GB', '+44', 10),
];

class ComposeSmsSheet extends StatefulWidget {
  final Function(String address, String message) onSend;

  const ComposeSmsSheet({super.key, required this.onSend});

  @override
  State<ComposeSmsSheet> createState() => _ComposeSmsSheetState();
}

class _ComposeSmsSheetState extends State<ComposeSmsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _messageController = TextEditingController();
  Country _selectedCountry = countries[0];

  @override
  void dispose() {
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Remove any leading zero if user typed it (common mistake)
      String number = _addressController.text.trim();
      if (number.startsWith('0')) {
        number = number.substring(1);
      }
      final fullAddress = '${_selectedCountry.dialCode}$number';
      widget.onSend(fullAddress, _messageController.text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compose New SMS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Country and Phone Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<Country>(
                    dropdownColor: Colors.white,
                    value: _selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    isExpanded: true,
                    items: countries.map((Country country) {
                      return DropdownMenuItem<Country>(
                        value: country,
                        child: Text(
                          '${country.code} ${country.dialCode}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (Country? newValue) {
                      setState(() {
                        _selectedCountry = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 9123456789',
                      prefixText: '${_selectedCountry.dialCode} ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      // Basic length check logic
                      String clean = value.trim();
                      if (clean.startsWith('0')) clean = clean.substring(1);

                      if (!RegExp(r'^\d+$').hasMatch(clean)) {
                        return 'Digits only';
                      }

                      if (clean.length != _selectedCountry.numberLength) {
                        // Allow small variance for countries with variable lengths like DE,
                        // but for this specific request "verify the length", strict is safer for PH/FR/ES
                        if (_selectedCountry.code == 'DE' &&
                            (clean.length >= 10 && clean.length <= 11)) {
                          return null;
                        }
                        return 'Enter ${_selectedCountry.numberLength} digits';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Send Message'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

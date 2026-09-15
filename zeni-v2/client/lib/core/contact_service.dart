import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactCallResult {
  final bool found;
  final String? matchedName;
  final String? phoneNumber;
  ContactCallResult({required this.found, this.matchedName, this.phoneNumber});
}

// Matches on first name (or any name part) rather than requiring the full
// name — "call pranav" should find "Pranav DYP" without the user spelling
// out the whole contact entry.
Future<ContactCallResult> findAndCall(String spokenName) async {
  final granted = await FlutterContacts.requestPermission();
  if (!granted) return ContactCallResult(found: false);

  final contacts = await FlutterContacts.getContacts(withProperties: true);
  final query = spokenName.trim().toLowerCase();

  final matches = contacts.where((c) {
    final displayName = c.displayName.toLowerCase();
    final nameParts = displayName.split(RegExp(r'\s+'));
    return nameParts.any((part) => part.startsWith(query)) || displayName.contains(query);
  }).toList();

  if (matches.isEmpty || matches.first.phones.isEmpty) {
    return ContactCallResult(found: false);
  }

  // Ambiguous matches (multiple people named "Pranav") just take the first —
  // no UI for disambiguation yet. Worth knowing if you have several contacts
  // sharing a first name.
  final contact = matches.first;
  final number = contact.phones.first.number;

  await launchUrl(Uri.parse('tel:$number'));

  return ContactCallResult(found: true, matchedName: contact.displayName, phoneNumber: number);
}

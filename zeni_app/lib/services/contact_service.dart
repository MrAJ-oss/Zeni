// ignore: unused_import
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  static Future<String?> getNumber(String name) async {
    await Permission.contacts.request();

    // ignore: non_constant_identifier_names, prefer_typing_uninitialized_variables
    var ContactsServiceplusS;
    Iterable contacts = await ContactsServiceplusS.getContacts();

    for (var c in contacts) {
      if (c.displayName != null &&
          c.displayName.toLowerCase().contains(name.toLowerCase())) {
        return c.phones.isNotEmpty ? c.phones.first.value : null;
      }
    }
    return null;
  }
}
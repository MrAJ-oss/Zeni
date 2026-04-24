import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  static Future<String?> getNumber(String name) async {
    await Permission.contacts.request();

    Iterable contacts = await ContactsService.getContacts();

    for (var c in contacts) {
      if (c.displayName != null &&
          c.displayName.toLowerCase().contains(name.toLowerCase())) {
        return c.phones.isNotEmpty ? c.phones.first.value : null;
      }
    }
    return null;
  }
}
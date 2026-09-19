import 'package:id_registry/id_registry.dart';

import 'support/id_storage_contract.dart';

void main() {
  idStorageContract(name: 'InMemoryIdStorage', build: InMemoryIdStorage.new);
}

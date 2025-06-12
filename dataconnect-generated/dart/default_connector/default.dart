// ignore: unnecessary_library_name
library default_connector;
import 'package:firebase_data_connect/firebase_data_connect.dart';
// ignore: unused_import
import 'dart:convert';







class DefaultConnector {
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'test1',
  );

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    return DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}


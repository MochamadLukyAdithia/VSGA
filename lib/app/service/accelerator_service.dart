
import 'package:vsga/app/models/Accellerator.dart';
import 'package:vsga/app/service/database_service.dart';

class AcceleratorService {
  DatabaseService _database = DatabaseService();
  Future<void> insertAacceleratorData(Accellerator data) async {
   try{
    _database.insertSensorAccelerometer(data.x!, data.y!, data.z!, data.timestamp);
     print('Accelerometer data inserted successfully');
   }catch (e) {
     print('Error inserting accelerator data: $e');
   }
  }
}
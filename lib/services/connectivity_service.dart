import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // utilizar el paquete connectivity_plus para monitorear el estado de la conexión
  final Connectivity connectivity = Connectivity();

  // metodo para verificar el estado actual de la conexión
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

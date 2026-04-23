import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // utilizar el paquete connectivity_plus para monitorear el estado de la conexión
  final Connectivity connectivity = Connectivity();

  // stream para reaccionar a cambios de conectividad en tiempo real
  // envia true si hay conexión, false si no hay conexión
  Stream<bool> get connectivityChanges => connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none)
      .distinct();

  // metodo para verificar el estado actual de la conexión
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

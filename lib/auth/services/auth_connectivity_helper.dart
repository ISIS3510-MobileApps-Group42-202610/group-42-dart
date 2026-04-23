import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/connectivity_service.dart';


// Helper de conectividad para login y eso,
// se encarga de monitorear el estado de la conexión y mostrar un snackbar cuando no hay conexión
mixin AuthConnectivityHelper<T extends StatefulWidget> on State<T> {
  final ConnectivityService connectivityService = ConnectivityService();
  StreamSubscription<bool>? connectivitySubscription;
  bool isConnectedT = true;
  bool hasConnectivityResultT = false;
  bool offlineSnackBarVisibleT = false;

  bool get isConnected => isConnectedT;
  bool get hasConnectivityResult => hasConnectivityResultT;

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  void startConnectivityMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final connected = await connectivityService.isConnected;
      applyConnectivityState(connected);

      await connectivitySubscription?.cancel();
      connectivitySubscription = connectivityService.connectivityChanges.listen(
        applyConnectivityState,
      );
    });
  }

  void showOfflineSnackBar([String message = 'No internet connection. Please try again later.']) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (offlineSnackBarVisibleT) return;

    offlineSnackBarVisibleT = true;
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
      ),
    );
  }

  void hideOfflineSnackBar() {
    if (!mounted) return;

    if (offlineSnackBarVisibleT) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      offlineSnackBarVisibleT = false;
    }
  }

  void applyConnectivityState(bool connected) {
    if (!mounted) return;

    hasConnectivityResultT = true;

    if (connected != isConnectedT) {
      setState(() => isConnectedT = connected);
    }

    if (connected) {
      hideOfflineSnackBar();
    } else {
      showOfflineSnackBar();
    }
  }
}



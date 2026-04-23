import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/connectivity_service.dart';
import 'repositories/auth_repository.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'data/auth_api_client.dart';
import 'data/auth_dio_client.dart';
import 'data/token_storage.dart';

class AuthProviders extends StatelessWidget {
  final Widget child;
  final String baseUrl;

  const AuthProviders({
    super.key,
    required this.child,
    this.baseUrl = 'https://group-42-backend.vercel.app/api/v1/', // url del api
  });

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dio = createDio(tokenStorage: tokenStorage, baseUrl: baseUrl);
    final apiClient = AuthApiClient(dio);
    // nuevo connectivity service para el bloc de auth
    final connectivityService = ConnectivityService();

    final repository = AuthRepository(
      apiTemp: apiClient,
      storageTemp: tokenStorage,
      connectivityServiceTemp: connectivityService,
    );

    return BlocProvider(
      create: (_) =>
          // ..add es para ejecutar el check session justo despues del bloc
          AuthBloc(
            repositoryTemp: repository,
          )..add(const AuthCheckSession()),
      child: child,
    );
  }
}

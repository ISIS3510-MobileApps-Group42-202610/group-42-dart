import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../analytics/analytics.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../theme/app_theme.dart';

enum ChatMode { buyer, seller }

class ChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String sellerName;
  final int? sellerId;
  final int? buyerId;
  final ChatMode mode;

  const ChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.sellerName,
    required this.sellerId,
    this.buyerId,
    this.mode = ChatMode.buyer,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  bool firstMessageSent = false;

  String? nearbyBuilding;
  String? locationStatusMessage;
  bool loadingLocation = false;

  final List<Map<String, dynamic>> universityBuildings = const [
    {'name': 'Mario Laserna (ML)', 'lat': 4.60320, 'lng': -74.06530},
    {'name': 'Edificio W', 'lat': 4.60250, 'lng': -74.06620},
    {'name': 'Edificio SD', 'lat': 4.60450, 'lng': -74.06580},
    {'name': 'Edificio RGD', 'lat': 4.60400, 'lng': -74.06550},
    {'name': 'Centro Deportivo', 'lat': 4.60550, 'lng': -74.06500},
    {'name': 'Edificio C', 'lat': 4.60300, 'lng': -74.06600},
    {'name': 'Edificio Q', 'lat': 4.60350, 'lng': -74.06560},
    {'name': 'Edificio O', 'lat': 4.60280, 'lng': -74.06570},
    {'name': 'Edificio B', 'lat': 4.60220, 'lng': -74.06610},
    {'name': 'Edificio Aulas', 'lat': 4.60380, 'lng': -74.06540},
    {'name': 'Edificio Au', 'lat': 4.60500, 'lng': -74.06480},
    {'name': 'Biblioteca General', 'lat': 4.60200, 'lng': -74.06640},
    {'name': 'Edificio Cívico', 'lat': 4.60230, 'lng': -74.06680},
    {'name': 'Edificio Franco', 'lat': 4.60420, 'lng': -74.06520},
    {'name': 'Edificio Lleras', 'lat': 4.60310, 'lng': -74.06580},
  ];

  double _toRad(double value) => value * math.pi / 180;

  double haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;

    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);

    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> loadNearbyBuilding() async {
    setState(() {
      loadingLocation = true;
      nearbyBuilding = null;
      locationStatusMessage = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        locationStatusMessage = 'Location services are disabled.';
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationStatusMessage = 'Location permission was denied.';
        return;
      }

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        locationStatusMessage = 'Could not get your location.';
        return;
      }

      final candidates = universityBuildings
          .map((building) {
        final distance = haversine(
          position!.latitude,
          position.longitude,
          building['lat'] as double,
          building['lng'] as double,
        );

        return {
          ...building,
          'distance': distance,
        };
      })
          .where((building) => (building['distance'] as double) <= 120)
          .toList()
        ..sort(
              (a, b) => (a['distance'] as double).compareTo(
            b['distance'] as double,
          ),
        );

      if (candidates.isNotEmpty) {
        nearbyBuilding = candidates.first['name'].toString();
      } else {
        final campusDistance = haversine(
          position.latitude,
          position.longitude,
          4.6040,
          -74.0658,
        );

        if (campusDistance <= 300) {
          nearbyBuilding = 'Uniandes Campus';
        } else {
          locationStatusMessage =
          'You are not close enough to campus to suggest a meeting point.';
        }
      }
    } catch (e) {
      locationStatusMessage = 'Could not check location: $e';
    } finally {
      if (mounted) {
        setState(() {
          loadingLocation = false;
        });
      }
    }
  }

  Dio getDio() {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      throw Exception('User is not authenticated');
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://group-42-backend.vercel.app/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${authState.accessToken}',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('[CHAT_DIO] ${options.method} ${options.path}');
          return handler.next(options);
        },
        onError: (error, handler) {
          print(
            '[CHAT_DIO] ERROR ${error.requestOptions.method} ${error.requestOptions.path}',
          );
          print('[CHAT_DIO] status: ${error.response?.statusCode}');
          print('[CHAT_DIO] response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMessages();
      loadNearbyBuilding();
    });
  }

  Future<void> loadMessages() async {
    setState(() {
      loading = true;
    });

    try {
      final dio = getDio();

      late final Response response;

      if (widget.mode == ChatMode.seller) {
        if (widget.buyerId == null || widget.buyerId! <= 0) {
          throw Exception('Invalid buyer id');
        }

        response = await dio.get('/messages/thread/buyer/${widget.buyerId}');
      } else {
        if (widget.sellerId == null || widget.sellerId! <= 0) {
          throw Exception('Invalid seller id');
        }

        response = await dio.get('/messages/thread/seller/${widget.sellerId}');
      }

      final data = response.data;

      if (data is List) {
        setState(() {
          messages = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          messages = [];
          loading = false;
        });
      }

      scrollToBottom();
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load chat: $e')),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
    });

    try {
      final dio = getDio();

      if (widget.mode == ChatMode.seller) {
        if (widget.buyerId == null || widget.buyerId! <= 0) {
          throw Exception('Invalid buyer id');
        }

        await dio.post(
          '/messages/seller',
          data: {
            'buyer_id': widget.buyerId,
            'content': text,
          },
        );
      } else {
        if (widget.sellerId == null || widget.sellerId! <= 0) {
          throw Exception('Invalid seller id');
        }

        await dio.post(
          '/messages/buyer',
          data: {
            'seller_id': widget.sellerId,
            'content': text,
          },
        );
      }

      final authState = context.read<AuthBloc>().state;

      if (!firstMessageSent && authState is AuthAuthenticated) {
        context.read<AnalyticsBloc>().add(
          TrackBusinessEvent(
            eventName: 'chat_started',
            listingId: widget.productId,
            buyerUserId: widget.mode == ChatMode.buyer
                ? authState.user.id
                : widget.buyerId,
            metadata: {
              'source': 'chat_screen',
              'mode': widget.mode.name,
              'product_id': widget.productId,
              'product_name': widget.productName,
              'seller_id': widget.sellerId,
              'buyer_id': widget.buyerId,
              'other_name': widget.sellerName,
            },
          ),
        );

        firstMessageSent = true;
      }

      controller.clear();
      await loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool isMyMessage(Map<String, dynamic> message) {
    final sentBy = message['sent_by'];

    if (widget.mode == ChatMode.seller) {
      return sentBy == 'seller';
    }

    return sentBy == 'buyer';
  }

  String messageText(Map<String, dynamic> message) {
    return (message['content'] ?? '').toString();
  }

  String messageTime(Map<String, dynamic> message) {
    final raw = message['sent_at'];
    if (raw == null) return '';

    try {
      final date = DateTime.parse(raw.toString()).toLocal();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  Widget quickMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          controller.text = text;
        },
      ),
    );
  }

  Widget locationBanner() {
    if (!loadingLocation && nearbyBuilding == null && locationStatusMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: loadingLocation
          ? const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text('Checking your nearby campus location...'),
          ),
        ],
      )
          : nearbyBuilding != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are near $nearbyBuilding',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.labelDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suggested meeting point: $nearbyBuilding lobby',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      )
          : Row(
        children: [
          const Icon(Icons.location_off_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              locationStatusMessage ?? 'Location unavailable.',
            ),
          ),
          TextButton(
            onPressed: loadNearbyBuilding,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.productName.trim().isEmpty ? 'Chat' : widget.productName;

    final subtitle = widget.mode == ChatMode.seller
        ? 'Buyer: ${widget.sellerName}'
        : 'Seller: ${widget.sellerName}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: loadNearbyBuilding,
            icon: const Icon(Icons.location_on_outlined),
          ),
          IconButton(
            onPressed: loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          locationBanner(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final mine = isMyMessage(msg);

                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? AppColors.primaryBlue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: mine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          messageText(msg),
                          style: TextStyle(
                            color: mine
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          messageTime(msg),
                          style: TextStyle(
                            fontSize: 10,
                            color: mine
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                quickMessage('Hola, ¿sigue disponible?'),
                quickMessage('Me interesa'),
                quickMessage('¿Podemos encontrarnos hoy?'),
                quickMessage('¿Cuál sería el precio final?'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: IconButton(
                      icon: sending
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: sending ? null : sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
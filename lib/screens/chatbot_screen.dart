import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chatbot_message.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/chatbot_provider.dart';
import '../utils/colors.dart';
import '../screens/map_location_picker.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  String? _selectedOption;  // Track selected option
  bool _optionsUsed = false;  // Track si opciones ya fueron usadas

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // Inicializar chatbot después de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final chatbotProvider = context.read<ChatbotProvider>();
      
      if (authProvider.currentUser != null) {
        final fullName = userProvider.profile?.fullName;
        chatbotProvider.initializeChatbot(
          authProvider.currentUser!,
          fullName: fullName,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatbotProvider = context.read<ChatbotProvider>();

    if (authProvider.currentUser != null) {
      chatbotProvider.sendMessage(message, authProvider.currentUser!);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ConVive Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Encuentra tu compañero ideal',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Tooltip(
            message: 'Reiniciar chat',
            child: IconButton(
              onPressed: () {
                final chatbotProvider = context.read<ChatbotProvider>();
                final authProvider = context.read<AuthProvider>();
                
                // Limpiar mensajes y reiniciar
                chatbotProvider.clearMessages();
                
                // Reinicializar con bienvenida
                if (authProvider.currentUser != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final userProvider = context.read<UserProvider>();
                    chatbotProvider.initializeChatbot(
                      authProvider.currentUser!,
                      fullName: userProvider.profile?.fullName,
                    );
                  });
                }
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            ),
          ),
        ],
      ),
      body: Consumer<ChatbotProvider>(
        builder: (context, chatbotProvider, _) {
          // Resetear _optionsUsed cuando llega un nuevo mensaje del asistente con opciones
          final msgs = chatbotProvider.messages;
          if (msgs.isNotEmpty) {
            final last = msgs.last;
            if (last.type == MessageType.assistant &&
                (last.options?.isNotEmpty ?? false) &&
                _optionsUsed) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => setState(() => _optionsUsed = false));
            }
          }
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primary.withOpacity(0.04),
                  AppColors.secondary.withOpacity(0.03),
                  Colors.grey.shade50,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: Column(
              children: [
                // Lista de mensajes
                Expanded(
                  child: chatbotProvider.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.15),
                                      AppColors.secondary.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  size: 60,
                                  color: AppColors.primary.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Iniciando conversación...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Responde las preguntas para encontrar\ntu compañero o departamento ideal',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          itemCount: chatbotProvider.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatbotProvider.messages[index];
                            return _buildMessage(context, message);
                          },
                        ),
                ),
                // Error si existe
                if (chatbotProvider.error != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chatbotProvider.error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Input de mensaje
                _buildMessageInput(chatbotProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ChatbotMessage message) {
    final isUserMessage = message.type == MessageType.user;

    // Detectar si el contenido tiene markdown (texto con formato)
    final hasMarkdown = message.content.contains('**') ||
        message.content.contains('\n- ') ||
        RegExp(r'\n\d+\.').hasMatch(message.content);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment:
            isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Mensaje normal
          if (message.type != MessageType.suggestion)
            Container(
              margin: EdgeInsets.only(
                bottom: 16,
                left: isUserMessage ? 60 : 0,
                right: isUserMessage ? 0 : (hasMarkdown ? 8 : 60),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: hasMarkdown ? 18 : 16,
              ),
              decoration: BoxDecoration(
                color: isUserMessage ? AppColors.primary : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isUserMessage
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                borderRadius: BorderRadius.circular(hasMarkdown ? 20 : 28),
                border: !isUserMessage
                    ? Border.all(color: Colors.grey.shade100, width: 1.2)
                    : null,
              ),
              child: isUserMessage
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 2),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.smart_toy, 
                              color: Colors.white, 
                              size: 16),
                          ),
                        ),
                        Flexible(
                          child: _buildFormattedContent(
                            message.content,
                            baseColor: Colors.black87,
                          ),
                        ),
                      ],
                    ),
            ),
          // Card de sugerencia (match)
          if (message.type == MessageType.suggestion)
            _buildSuggestionCard(context, message),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, ChatbotMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con chip de compatibilidad
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Coincidencia encontrada para ti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Badge de score
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((message.compatibilityScore ?? 0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Avatar, nombre y barra de compatibilidad
          Row(
            children: [
              // Avatar con borde
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: message.matchedUserAvatar != null
                      ? CachedNetworkImage(
                          imageUrl: message.matchedUserAvatar!,
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 66,
                            height: 66,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person,
                                color: Colors.grey, size: 30),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary
                                ],
                              ),
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 30),
                          ),
                        )
                      : Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.matchedUserName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Barra de compatibilidad
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (message.compatibilityScore ?? 0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((message.compatibilityScore ?? 0) * 100).toStringAsFixed(0)}% compatible contigo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Separador
          Divider(color: AppColors.primary.withOpacity(0.15), height: 1),
          const SizedBox(height: 12),
          // Descripción formateada
          _buildFormattedContent(message.content,
              baseColor: Colors.black87, baseFontSize: 14),
          const SizedBox(height: 14),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUserDetails(context, message),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Ver Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (message.propertyLocation != null) {
                      final lat = message.propertyLocation!['lat'] as double?;
                      final lng = message.propertyLocation!['lng'] as double?;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MapLocationPicker(
                            initialLat: lat,
                            initialLng: lng,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('Ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatbotProvider chatbotProvider) {
    // Obtener último mensaje del asistente que tenga opciones
    ChatbotMessage? lastMessage;
    for (int i = chatbotProvider.messages.length - 1; i >= 0; i--) {
      if (chatbotProvider.messages[i].type == MessageType.assistant &&
          (chatbotProvider.messages[i].options?.isNotEmpty ?? false)) {
        lastMessage = chatbotProvider.messages[i];
        break;
      }
    }

    // Input de texto normal
    Widget textInputWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: chatbotProvider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.primary,
            onPressed: chatbotProvider.isLoading ? null : _sendMessage,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );

    // Siempre mostrar solo el input de texto (sin botones de opciones)
    // Mostrar botones de opciones si el último mensaje del asistente los tiene
    if (lastMessage != null && !_optionsUsed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chips de opciones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lastMessage.options!.map((option) {
                return GestureDetector(
                  onTap: chatbotProvider.isLoading
                      ? null
                      : () {
                          setState(() => _optionsUsed = true);
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.currentUser != null) {
                            context.read<ChatbotProvider>().sendMessage(
                                  option,
                                  authProvider.currentUser!,
                                );
                            _scrollToBottom();
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.12),
                          AppColors.secondary.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.35), width: 1.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          textInputWidget,
        ],
      );
    }

    return textInputWidget;
  }

  // ─── Renderizador de Markdown ───────────────────────────────────────────

  Widget _buildFormattedContent(
    String text, {
    Color baseColor = Colors.black87,
    double baseFontSize = 15,
  }) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      widgets.add(_buildFormattedLine(line, baseColor: baseColor, baseFontSize: baseFontSize));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildFormattedLine(
    String line, {
    required Color baseColor,
    required double baseFontSize,
  }) {
    final trimmed = line.trim();

    // Línea vacía → pequeño espaciado
    if (trimmed.isEmpty) return const SizedBox(height: 5);

    // Encabezado: línea rodeada de ** (e.g. **Recomendación 1: ...**)
    final headerMatch = RegExp(r'^\*\*(.+)\*\*$').firstMatch(trimmed);
    if (headerMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 3),
        child: Text(
          headerMatch.group(1)!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize + 0.5,
            color: AppColors.primary,
            height: 1.4,
          ),
        ),
      );
    }

    // Bullet: empieza con '- ' o '• '
    if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
      final content = trimmed.substring(2);
      return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7, right: 8),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: _buildInlineRichText(content,
                  baseColor: baseColor, baseFontSize: baseFontSize),
            ),
          ],
        ),
      );
    }

    // Lista numerada: e.g. '1. Texto'
    final numberedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(trimmed);
    if (numberedMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  numberedMatch.group(1)!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Flexible(
              child: _buildInlineRichText(numberedMatch.group(2)!,
                  baseColor: baseColor, baseFontSize: baseFontSize),
            ),
          ],
        ),
      );
    }

    // Texto normal
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: _buildInlineRichText(trimmed,
          baseColor: baseColor, baseFontSize: baseFontSize),
    );
  }

  Widget _buildInlineRichText(
    String text, {
    required Color baseColor,
    required double baseFontSize,
  }) {
    final baseStyle = TextStyle(
      color: baseColor,
      fontSize: baseFontSize,
      height: 1.5,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    final parts = text.split(RegExp(r'\*\*'));
    if (parts.length == 1) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? boldStyle : baseStyle,
      ));
    }
    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  void _showUserDetails(BuildContext context, ChatbotMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: message.matchedUserAvatar != null
                      ? CachedNetworkImage(
                          imageUrl: message.matchedUserAvatar!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: AppColors.primary,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 40),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.matchedUserName ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '${(message.compatibilityScore ?? 0).toStringAsFixed(0)}% Compatible',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Detalles del Perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFormattedContent(message.content, baseColor: Colors.black87),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

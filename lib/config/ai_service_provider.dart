import '../services/ai_service.dart';
import 'app_config.dart';

class AIServiceProvider {
  static late AIService _aiService;

  /// Inicializar servicio de IA
  static void initialize() {
    _aiService = AIService(baseUrl: AppConfig.aiServiceUrl);
  }

  static AIService get instance => _aiService;

  /// Liberar recursos
  static void dispose() {
    _aiService.dispose();
  }
}

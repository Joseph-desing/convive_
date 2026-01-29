import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayuda y soporte',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSection(
              title: 'Contacto',
              children: [
                _buildContactTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'changoluizajoseph0@gmail.com',
                  onTap: () => _launchEmail(),
                ),
                const Divider(height: 1),
                _buildContactTile(
                  icon: Icons.phone_outlined,
                  title: 'Teléfono',
                  subtitle: '+593 983 340 6747',
                  onTap: () => _launchPhone(),
                ),
                const Divider(height: 1),
                _buildContactTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat en vivo',
                  subtitle: 'Disponible 9am - 6pm',
                  onTap: () => _showComingSoonDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Preguntas frecuentes',
              children: [
                _buildFAQTile(
                  question: '¿Cómo puedo publicar una propiedad?',
                  answer: 'Ve a la pestaña "Publicar", completa el formulario con los detalles de tu propiedad y sube fotos. Una vez enviado, tu anuncio será visible para otros usuarios.',
                ),
                const Divider(height: 1),
                _buildFAQTile(
                  question: '¿Cómo encuentro un compañero/a compatible?',
                  answer: 'Usa los filtros de búsqueda para encontrar personas con hábitos y preferencias similares. Puedes ver sus perfiles y enviar solicitudes de contacto.',
                ),
                const Divider(height: 1),
                _buildFAQTile(
                  question: '¿Es seguro compartir mi información?',
                  answer: 'Sí, toda tu información está protegida con encriptación. Solo compartes lo que decides mostrar en tu perfil público.',
                ),
                const Divider(height: 1),
                _buildFAQTile(
                  question: '¿Cómo verifico mi cuenta?',
                  answer: 'La verificación se realiza mediante tu email universitario o documentos de identidad. Contacta al soporte para más información.',
                ),
                const Divider(height: 1),
                _buildFAQTile(
                  question: '¿Qué hago si tengo un problema con otro usuario?',
                  answer: 'Puedes reportar usuarios desde su perfil. Nuestro equipo revisará el caso en un plazo de 24-48 horas.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Recursos',
              children: [
                _buildResourceTile(
                  icon: Icons.book_outlined,
                  title: 'Guía de uso',
                  subtitle: 'Aprende a usar ConVive',
                  onTap: () => _showComingSoonDialog(context),
                ),
                const Divider(height: 1),
                _buildResourceTile(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'Consejos de seguridad',
                  subtitle: 'Cómo encontrar compañero/a seguro',
                  onTap: () => _showSafetyTipsDialog(context),
                ),
                const Divider(height: 1),
                _buildResourceTile(
                  icon: Icons.article_outlined,
                  title: 'Blog',
                  subtitle: 'Artículos y noticias',
                  onTap: () => _showComingSoonDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Legal',
              children: [
                _buildResourceTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  subtitle: 'Lee nuestros términos de uso',
                  onTap: () => _showComingSoonDialog(context),
                ),
                const Divider(height: 1),
                _buildResourceTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de privacidad',
                  subtitle: 'Cómo protegemos tus datos',
                  onTap: () => _showComingSoonDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'ConVive',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildResourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildFAQTile({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      leading: Icon(Icons.help_outline, color: AppColors.primary),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'soporte@convive.com',
      query: 'subject=Solicitud de ayuda ConVive',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+521234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Próximamente'),
        content: const Text('Esta función estará disponible pronto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showSafetyTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consejos de seguridad'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '• Conoce a tu futuro compañero/a en persona antes de firmar\n\n'
                '• Revisa referencias y verifica identidad\n\n'
                '• No compartas información financiera sensible\n\n'
                '• Visita la propiedad antes de comprometerte\n\n'
                '• Lee bien el contrato de arrendamiento\n\n'
                '• Confía en tu intuición\n\n'
                '• Reporta comportamiento sospechoso',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

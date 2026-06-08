import 'package:flutter_test/flutter_test.dart';

bool validarTituloInformativo(String titulo) {
  return titulo.trim().isNotEmpty;
}

bool validarDescripcionInformativa(String descripcion) {
  return descripcion.trim().length >= 10;
}

bool validarCaracteristica(String caracteristica) {
  final caracteristicasPermitidas = [
    'Búsqueda de departamentos',
    'Recomendación de compañeros',
    'Chatbot',
    'Notificaciones',
    'Chat en tiempo real',
    'Perfil de usuario',
  ];

  return caracteristicasPermitidas.contains(caracteristica);
}

bool pantallaInformativaValida({
  required String titulo,
  required String descripcion,
  required List<String> caracteristicas,
}) {
  return validarTituloInformativo(titulo) &&
      validarDescripcionInformativa(descripcion) &&
      caracteristicas.isNotEmpty &&
      caracteristicas.every(validarCaracteristica);
}

void main() {
  group('InformationScreenTest - Pruebas unitarias para la pantalla informativa', () {
    test('Pantalla informativa no permite título vacío', () {
      expect(
        pantallaInformativaValida(
          titulo: '',
          descripcion: 'Pantalla informativa de la aplicación ConVive.',
          caracteristicas: ['Búsqueda de departamentos'],
        ),
        false,
      );
    });

    test('Pantalla informativa no permite descripción muy corta', () {
      expect(
        pantallaInformativaValida(
          titulo: 'ConVive',
          descripcion: 'Info',
          caracteristicas: ['Búsqueda de departamentos'],
        ),
        false,
      );
    });

    test('Pantalla informativa no permite lista de características vacía', () {
      expect(
        pantallaInformativaValida(
          titulo: 'ConVive',
          descripcion: 'Pantalla informativa de la aplicación ConVive.',
          caracteristicas: [],
        ),
        false,
      );
    });

    test('Pantalla informativa no permite característica inválida', () {
      expect(
        pantallaInformativaValida(
          titulo: 'ConVive',
          descripcion: 'Pantalla informativa de la aplicación ConVive.',
          caracteristicas: ['Pagos bancarios'],
        ),
        false,
      );
    });

    test('Pantalla informativa permite una característica válida', () {
      expect(
        pantallaInformativaValida(
          titulo: 'ConVive',
          descripcion: 'Pantalla informativa de la aplicación ConVive.',
          caracteristicas: ['Chatbot'],
        ),
        true,
      );
    });

    test('Pantalla informativa permite varias características válidas', () {
      expect(
        pantallaInformativaValida(
          titulo: 'Características de ConVive',
          descripcion: 'Esta pantalla muestra las funcionalidades principales disponibles en la aplicación móvil.',
          caracteristicas: [
            'Búsqueda de departamentos',
            'Recomendación de compañeros',
            'Chatbot',
            'Notificaciones',
          ],
        ),
        true,
      );
    });
  });
}
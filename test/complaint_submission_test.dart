import 'package:flutter_test/flutter_test.dart';

bool validarTipoQuejaSugerencia(String tipo) {
  final tiposPermitidos = [
    'Queja',
    'Sugerencia',
    'Recomendación',
  ];

  return tiposPermitidos.contains(tipo);
}

bool validarTituloQuejaSugerencia(String titulo) {
  return titulo.trim().isNotEmpty && titulo.trim().length >= 5;
}

bool validarDescripcionQuejaSugerencia(String descripcion) {
  return descripcion.trim().length >= 10;
}

bool validarCorreoUsuario(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool envioQuejaSugerenciaValido({
  required String tipo,
  required String titulo,
  required String descripcion,
  required String correoUsuario,
}) {
  return validarTipoQuejaSugerencia(tipo) &&
      validarTituloQuejaSugerencia(titulo) &&
      validarDescripcionQuejaSugerencia(descripcion) &&
      validarCorreoUsuario(correoUsuario);
}

void main() {
  group(
    'ComplaintSubmissionTest - Pruebas unitarias para el envío de quejas y sugerencias ConVive',
        () {
      test('Envío no permite tipo vacío', () {
        print('Validando envío de queja/sugerencia con tipo vacío...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: '',
          titulo: 'Error de carga',
          descripcion: 'La aplicación presenta un inconveniente al cargar.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: vacío');
        print('Título: Error de carga');
        print('Descripción: La aplicación presenta un inconveniente al cargar.');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Envío no permite tipo inválido', () {
        print('Validando envío de queja/sugerencia con tipo inválido...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Comentario',
          titulo: 'Error de carga',
          descripcion: 'La aplicación presenta un inconveniente al cargar.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo recibido: Comentario');
        print('Título: Error de carga');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Envío no permite título vacío', () {
        print('Validando envío de queja/sugerencia con título vacío...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Queja',
          titulo: '',
          descripcion: 'La aplicación presenta un inconveniente al cargar.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: Queja');
        print('Título: vacío');
        print('Descripción: La aplicación presenta un inconveniente al cargar.');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Envío no permite título demasiado corto', () {
        print('Validando envío de queja/sugerencia con título corto...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Queja',
          titulo: 'App',
          descripcion: 'La aplicación presenta un inconveniente al cargar.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: Queja');
        print('Título recibido: App');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Envío no permite descripción demasiado corta', () {
        print('Validando envío de queja/sugerencia con descripción corta...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Sugerencia',
          titulo: 'Mejora',
          descripcion: 'Malo',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: Sugerencia');
        print('Título: Mejora');
        print('Descripción recibida: Malo');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Envío no permite correo inválido', () {
        print('Validando envío de queja/sugerencia con correo inválido...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Recomendación',
          titulo: 'Mejora de búsqueda',
          descripcion: 'Sugiero mejorar los filtros de búsqueda.',
          correoUsuario: 'changoluizajoseph0gmail.com',
        );

        print('Usuario recibido: changoluizajoseph0gmail.com');
        print('Tipo: Recomendación');
        print('Título: Mejora de búsqueda');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Envío permite queja válida', () {
        print('Validando envío válido de queja...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Queja',
          titulo: 'Comportamiento inapropiado',
          descripcion:
          'La pantalla tarda demasiado en cargar los departamentos disponibles.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: Byron Loarte');
        print('Tipo: Queja');

        print('Comportamiento inapropiado');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Envío permite sugerencia válida', () {
        print('Validando envío válido de sugerencia...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Sugerencia',
          titulo: 'Mejorar filtros',
          descripcion:
          'Sería útil agregar filtros por sector, presupuesto y servicios disponibles.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: Sugerencia');
        print('Título: Mejorar filtros');
        print('Descripción: Sería útil agregar filtros por sector, presupuesto y servicios disponibles.');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Envío permite recomendación válida', () {
        print('Validando envío válido de recomendación...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Recomendación',
          titulo: 'Agregar tutorial',
          descripcion:
          'Se recomienda agregar una guía inicial para nuevos usuarios de ConVive.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: Recomendación');
        print('Título: Agregar tutorial');
        print('Descripción: Se recomienda agregar una guía inicial para nuevos usuarios de ConVive.');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Envío permite reporte de mejora funcional válido', () {
        print('Validando recomendación funcional válida para ConVive...');

        final resultado = envioQuejaSugerenciaValido(
          tipo: 'Sugerencia',
          titulo: 'Optimizar chatbot',
          descripcion:
          'Se sugiere mejorar las respuestas del chatbot para encontrar departamentos compatibles.',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Tipo: Sugerencia');
        print('Título: Optimizar chatbot');
        print('Descripción: Se sugiere mejorar las respuestas del chatbot para encontrar departamentos compatibles.');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
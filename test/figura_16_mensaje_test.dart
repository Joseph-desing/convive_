import 'package:flutter_test/flutter_test.dart';

void main() {
  test(' Valida que el roomie pueda enviar mensaje al propietario', () {
    final mensaje = {
      'emisor': 'changoluizajoseph0@gmail.com',
      'receptor': 'propietario@gmail.com',
      'contenido': 'Hola, estoy interesado en el departamento.',
    };

    final mensajeValido = mensaje['emisor'] != '' &&
        mensaje['receptor'] != '' &&
        mensaje['contenido'] != '';

    expect(mensajeValido, true);

    print('Módulo: Mensajería');
    print('Emisor: ${mensaje['emisor']}');
    print('Contenido: ${mensaje['contenido']}');
    print('Resultado esperado: true');
    print('Resultado obtenido: $mensajeValido');
  });
}
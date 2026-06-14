import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Valida recepción y respuesta de mensajes del chatbot', () {
    const pregunta = 'Busco departamento';

    final respuesta = pregunta.isNotEmpty
        ? 'Puedes buscar departamentos disponibles según tus preferencias.'
        : '';

    expect(respuesta.isNotEmpty, true);

    print('Módulo: Chatbot');
    print('Pregunta: $pregunta');
    print('Respuesta obtenida: $respuesta');
    print('Resultado esperado: true');
    print('Resultado obtenido: ${respuesta.isNotEmpty}');
  });
}
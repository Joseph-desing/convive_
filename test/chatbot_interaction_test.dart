import 'package:flutter_test/flutter_test.dart';

bool validarMensajeUsuario(String mensaje) {
  return mensaje.trim().isNotEmpty;
}

bool validarRespuestaChatbot(String respuesta) {
  return respuesta.trim().isNotEmpty && respuesta.trim().length >= 10;
}

bool validarIntencionChatbot(String intencion) {
  final intencionesPermitidas = [
    'buscar_departamento',
    'buscar_companero',
    'cambiar_preferencias',
    'mostrar_recomendaciones',
    'ayuda',
  ];

  return intencionesPermitidas.contains(intencion);
}

bool validarTipoBusquedaChatbot(String tipoBusqueda) {
  final tiposPermitidos = [
    'Departamento',
    'Compañero',
    'Habitación',
    'Ayuda',
  ];

  return tiposPermitidos.contains(tipoBusqueda);
}

bool interaccionChatbotValida({
  required String mensajeUsuario,
  required String respuestaChatbot,
  required String intencion,
  required String tipoBusqueda,
}) {
  return validarMensajeUsuario(mensajeUsuario) &&
      validarRespuestaChatbot(respuestaChatbot) &&
      validarIntencionChatbot(intencion) &&
      validarTipoBusquedaChatbot(tipoBusqueda);
}

void main() {
  group(
    'ChatbotInteractionTest - Pruebas unitarias de interacción con chatbot ConVive',
        () {
      test('Chatbot no permite mensaje vacío del usuario', () {
        print('Validando interacción con mensaje vacío en el chatbot...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: '',
          respuestaChatbot: 'Hola, puedo ayudarte a encontrar vivienda.',
          intencion: 'ayuda',
          tipoBusqueda: 'Ayuda',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: vacío');
        print('Respuesta chatbot: Hola, puedo ayudarte a encontrar vivienda.');
        print('Intención: ayuda');
        print('Tipo búsqueda: Ayuda');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Chatbot no permite respuesta vacía', () {
        print('Validando interacción con respuesta vacía del chatbot...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Busco departamento',
          respuestaChatbot: '',
          intencion: 'buscar_departamento',
          tipoBusqueda: 'Departamento',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Busco departamento');
        print('Respuesta chatbot: vacía');
        print('Intención: buscar_departamento');
        print('Tipo búsqueda: Departamento');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Chatbot no permite respuesta demasiado corta', () {
        print('Validando interacción con respuesta demasiado corta...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Busco departamento',
          respuestaChatbot: 'Ok',
          intencion: 'buscar_departamento',
          tipoBusqueda: 'Departamento',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Busco departamento');
        print('Respuesta chatbot: Ok');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Chatbot no permite intención inválida', () {
        print('Validando interacción con intención inválida...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Busco departamento',
          respuestaChatbot:
          'Estoy buscando departamentos disponibles para ti.',
          intencion: 'comprar_producto',
          tipoBusqueda: 'Departamento',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Busco departamento');
        print('Respuesta chatbot: Estoy buscando departamentos disponibles para ti.');
        print('Intención recibida: comprar_producto');
        print('Tipo búsqueda: Departamento');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Chatbot no permite tipo de búsqueda inválido', () {
        print('Validando interacción con tipo de búsqueda inválido...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Busco departamento',
          respuestaChatbot:
          'Estoy buscando departamentos disponibles para ti.',
          intencion: 'buscar_departamento',
          tipoBusqueda: 'Vehículo',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Busco departamento');
        print('Intención: buscar_departamento');
        print('Tipo búsqueda recibido: Vehículo');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Chatbot permite búsqueda válida de departamento', () {
        print('Validando búsqueda válida de departamento con chatbot...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Busco un departamento cerca de la universidad',
          respuestaChatbot:
          'Estoy buscando departamentos disponibles que se ajusten a tus preferencias.',
          intencion: 'buscar_departamento',
          tipoBusqueda: 'Departamento',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Busco un departamento cerca de la universidad');
        print('Respuesta chatbot: Estoy buscando departamentos disponibles que se ajusten a tus preferencias.');
        print('Intención: buscar_departamento');
        print('Tipo búsqueda: Departamento');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Chatbot permite búsqueda válida de compañero', () {
        print('Validando búsqueda válida de compañero con chatbot...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Quiero encontrar un compañero de habitación',
          respuestaChatbot:
          'Estoy buscando compañeros compatibles según tus preferencias registradas.',
          intencion: 'buscar_companero',
          tipoBusqueda: 'Compañero',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Quiero encontrar un compañero de habitación');
        print('Respuesta chatbot: Estoy buscando compañeros compatibles según tus preferencias registradas.');
        print('Intención: buscar_companero');
        print('Tipo búsqueda: Compañero');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Chatbot permite cambio de preferencias', () {
        print('Validando cambio de preferencias desde chatbot...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Deseo cambiar mis preferencias de búsqueda',
          respuestaChatbot:
          'Puedes modificar tus preferencias para mejorar las recomendaciones.',
          intencion: 'cambiar_preferencias',
          tipoBusqueda: 'Ayuda',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Deseo cambiar mis preferencias de búsqueda');
        print('Respuesta chatbot: Puedes modificar tus preferencias para mejorar las recomendaciones.');
        print('Intención: cambiar_preferencias');
        print('Tipo búsqueda: Ayuda');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Chatbot permite mostrar recomendaciones disponibles', () {
        print('Validando visualización de recomendaciones desde chatbot...');

        final resultado = interaccionChatbotValida(
          mensajeUsuario: 'Sí, mostrar departamentos',
          respuestaChatbot:
          'Te muestro las opciones disponibles que encontré según tus preferencias.',
          intencion: 'mostrar_recomendaciones',
          tipoBusqueda: 'Departamento',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Mensaje usuario: Sí, mostrar departamentos');
        print('Respuesta chatbot: Te muestro las opciones disponibles que encontré según tus preferencias.');
        print('Intención: mostrar_recomendaciones');
        print('Tipo búsqueda: Departamento');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
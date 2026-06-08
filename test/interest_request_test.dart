import 'package:flutter_test/flutter_test.dart';

bool validarUsuarioSolicitante(String usuarioId) {
  return usuarioId.trim().isNotEmpty;
}

bool validarPublicacionInteres(String publicacionId) {
  return publicacionId.trim().isNotEmpty;
}

bool validarTipoSolicitud(String tipo) {
  final tiposPermitidos = [
    'Departamento',
    'Compañero',
    'Habitación',
  ];

  return tiposPermitidos.contains(tipo);
}

bool validarEstadoSolicitud(String estado) {
  final estadosPermitidos = [
    'Pendiente',
    'Aceptada',
    'Rechazada',
  ];

  return estadosPermitidos.contains(estado);
}

bool validarMensajeSolicitud(String mensaje) {
  return mensaje.trim().isEmpty || mensaje.trim().length >= 10;
}

bool solicitudInteresValida({
  required String usuarioId,
  required String publicacionId,
  required String tipo,
  required String estado,
  required String mensaje,
}) {
  return validarUsuarioSolicitante(usuarioId) &&
      validarPublicacionInteres(publicacionId) &&
      validarTipoSolicitud(tipo) &&
      validarEstadoSolicitud(estado) &&
      validarMensajeSolicitud(mensaje);
}

void main() {
  group(
    'InterestRequestTest - Pruebas unitarias de envío de solicitudes de interés ConVive',
        () {
      test('Solicitud no permite usuario solicitante vacío', () {
        print('Validando solicitud de interés con usuario vacío...');

        final resultado = solicitudInteresValida(
          usuarioId: '',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Departamento',
          estado: 'Pendiente',
          mensaje: 'Estoy interesado en esta vivienda.',
        );

        print('Usuario solicitante: vacío');
        print('Publicación: Departamento en la Alameda');
        print('Tipo: Departamento');
        print('Estado: Pendiente');
        print('Mensaje: Estoy interesado en esta vivienda.');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Solicitud no permite publicación vacía', () {
        print('Validando solicitud de interés con publicación vacía...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: '',
          tipo: 'Departamento',
          estado: 'Pendiente',
          mensaje: 'Estoy interesado en esta vivienda.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: vacía');
        print('Tipo: Departamento');
        print('Estado: Pendiente');
        print('Mensaje: Estoy interesado en esta vivienda.');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Solicitud no permite tipo de solicitud inválido', () {
        print('Validando solicitud de interés con tipo inválido...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Vehículo',
          estado: 'Pendiente',
          mensaje: 'Estoy interesado en esta vivienda.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Departamento en la Alameda');
        print('Tipo recibido: Vehículo');
        print('Estado: Pendiente');
        print('Mensaje: Estoy interesado en esta vivienda.');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Solicitud no permite estado inválido', () {
        print('Validando solicitud de interés con estado inválido...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Departamento',
          estado: 'Archivada',
          mensaje: 'Estoy interesado en esta vivienda.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Departamento en la Alameda');
        print('Tipo: Departamento');
        print('Estado recibido: Archivada');
        print('Mensaje: Estoy interesado en esta vivienda.');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Solicitud no permite mensaje demasiado corto si se ingresa texto', () {
        print('Validando solicitud de interés con mensaje demasiado corto...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Departamento',
          estado: 'Pendiente',
          mensaje: 'Hola',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Departamento en la Alameda');
        print('Tipo: Departamento');
        print('Estado: Pendiente');
        print('Mensaje recibido: Hola');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Solicitud permite mensaje vacío porque es opcional', () {
        print('Validando solicitud de interés con mensaje opcional vacío...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Departamento',
          estado: 'Pendiente',
          mensaje: '',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Departamento en la Alameda');
        print('Tipo: Departamento');
        print('Estado: Pendiente');
        print('Mensaje: vacío opcional');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Solicitud permite interés válido por departamento', () {
        print('Validando solicitud válida de interés por departamento...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Departamento',
          estado: 'Pendiente',
          mensaje: 'Estoy interesado en conocer más sobre este departamento.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Departamento en la Alameda');
        print('Tipo: Departamento');
        print('Estado: Pendiente');
        print('Mensaje: Estoy interesado en conocer más sobre este departamento.');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Solicitud permite interés válido por habitación', () {
        print('Validando solicitud válida de interés por habitación...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Habitación xd',
          tipo: 'Habitación',
          estado: 'Pendiente',
          mensaje: 'Estoy interesado en conocer más sobre esta habitación.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Habitación xd');
        print('Tipo: Habitación');
        print('Estado: Pendiente');
        print('Mensaje: Estoy interesado en conocer más sobre esta habitación.');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Solicitud permite interés válido por compañero', () {
        print('Validando solicitud válida de interés por compañero...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Búsqueda de compañero de habitación',
          tipo: 'Compañero',
          estado: 'Pendiente',
          mensaje: 'Me interesa conversar sobre esta búsqueda de compañero.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Búsqueda de compañero de habitación');
        print('Tipo: Compañero');
        print('Estado: Pendiente');
        print('Mensaje: Me interesa conversar sobre esta búsqueda de compañero.');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Solicitud permite estado aceptada válido', () {
        print('Validando solicitud de interés con estado aceptada...');

        final resultado = solicitudInteresValida(
          usuarioId: 'changoluizajoseph0@gmail.com',
          publicacionId: 'Departamento en la Alameda',
          tipo: 'Departamento',
          estado: 'Aceptada',
          mensaje: 'La solicitud fue aceptada correctamente por el propietario.',
        );

        print('Usuario solicitante: changoluizajoseph0@gmail.com');
        print('Publicación: Departamento en la Alameda');
        print('Tipo: Departamento');
        print('Estado: Aceptada');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
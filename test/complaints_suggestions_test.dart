import 'package:flutter_test/flutter_test.dart';

bool validarTipoReporte(String tipo) {
  final tiposPermitidos = [
    'Queja',
    'Sugerencia',
    'Reporte',
    'Recomendación',
  ];

  return tiposPermitidos.contains(tipo);
}

bool validarDescripcionReporte(String descripcion) {
  return descripcion.trim().length >= 10;
}

bool validarEstadoReporte(String estado) {
  final estadosPermitidos = [
    'Pendiente',
    'En revisión',
    'Resuelto',
    'Rechazado',
  ];

  return estadosPermitidos.contains(estado);
}

bool validarCorreoUsuarioReporte(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool reporteAdministrativoValido({
  required String tipo,
  required String descripcion,
  required String estado,
  required String correoUsuario,
}) {
  return validarTipoReporte(tipo) &&
      validarDescripcionReporte(descripcion) &&
      validarEstadoReporte(estado) &&
      validarCorreoUsuarioReporte(correoUsuario);
}

void main() {
  group(
    'ComplaintsSuggestionsTest - Pruebas unitarias de gestión administrativa de quejas y sugerencias ConVive',
        () {
      test('Gestión no permite tipo de reporte vacío', () {
        print('Validando gestión administrativa con tipo de reporte vacío...');

        final resultado = reporteAdministrativoValido(
          tipo: '',
          descripcion: 'El usuario reporta un problema con una publicación.',
          estado: 'Pendiente',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: vacío');
        print('Descripción: El usuario reporta un problema con una publicación.');
        print('Estado: Pendiente');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Gestión no permite tipo de reporte inválido', () {
        print('Validando gestión administrativa con tipo inválido...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Comentario',
          descripcion: 'El usuario reporta un problema con una publicación.',
          estado: 'Pendiente',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo recibido: Comentario');
        print('Estado: Pendiente');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Gestión no permite descripción muy corta', () {
        print('Validando gestión administrativa con descripción corta...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Queja',
          descripcion: 'Malo',
          estado: 'Pendiente',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: Queja');
        print('Descripción recibida: Malo');
        print('Estado: Pendiente');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Gestión no permite estado inválido', () {
        print('Validando gestión administrativa con estado inválido...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Queja',
          descripcion: 'El usuario reporta un problema con una publicación.',
          estado: 'Archivado',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: Queja');
        print('Estado recibido: Archivado');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Gestión no permite correo de usuario inválido', () {
        print('Validando gestión administrativa con correo inválido...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Sugerencia',
          descripcion: 'El usuario sugiere mejorar la información de las viviendas.',
          estado: 'Pendiente',
          correoUsuario: 'changoluizajoseph0gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario recibido: changoluizajoseph0gmail.com');
        print('Tipo: Sugerencia');
        print('Estado: Pendiente');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Gestión permite queja válida en revisión', () {
        print('Validando gestión administrativa de queja válida...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Queja',
          descripcion: 'El usuario reporta un problema con una publicación.',
          estado: 'En revisión',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: Queja');
        print('Descripción: El usuario reporta un problema con una publicación.');
        print('Estado: En revisión');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Gestión permite sugerencia válida pendiente', () {
        print('Validando gestión administrativa de sugerencia válida...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Sugerencia',
          descripcion:
          'El usuario sugiere mejorar el proceso de búsqueda de viviendas.',
          estado: 'Pendiente',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: Sugerencia');
        print('Estado: Pendiente');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Gestión permite recomendación válida', () {
        print('Validando gestión administrativa de recomendación válida...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Recomendación',
          descripcion:
          'El usuario recomienda agregar una guía para nuevos usuarios.',
          estado: 'Pendiente',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: Recomendación');
        print('Estado: Pendiente');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Gestión permite reporte resuelto válido', () {
        print('Validando reporte administrativo resuelto...');

        final resultado = reporteAdministrativoValido(
          tipo: 'Reporte',
          descripcion:
          'El administrador marcó el reporte como solucionado correctamente.',
          estado: 'Resuelto',
          correoUsuario: 'changoluizajoseph0@gmail.com',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario que envía reporte: changoluizajoseph0@gmail.com');
        print('Tipo: Reporte');
        print('Estado: Resuelto');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
import 'package:flutter_test/flutter_test.dart';

bool validarTituloDepartamento(String titulo) {
  return titulo.trim().isNotEmpty;
}

bool validarPrecioDepartamento(double precio) {
  return precio > 0;
}

bool validarUbicacionDepartamento(String ubicacion) {
  return ubicacion.trim().isNotEmpty;
}

bool validarEstadoDepartamento(String estado) {
  final estadosPermitidos = [
    'Publicado',
    'Pendiente',
    'Rechazado',
    'Inactivo',
  ];

  return estadosPermitidos.contains(estado);
}

bool validarTipoDepartamento(String tipo) {
  final tiposPermitidos = [
    'Departamento',
    'Habitación',
    'Casa',
  ];

  return tiposPermitidos.contains(tipo);
}

bool departamentoAdministrativoValido({
  required String titulo,
  required double precio,
  required String ubicacion,
  required String estado,
  required String tipo,
}) {
  return validarTituloDepartamento(titulo) &&
      validarPrecioDepartamento(precio) &&
      validarUbicacionDepartamento(ubicacion) &&
      validarEstadoDepartamento(estado) &&
      validarTipoDepartamento(tipo);
}

void main() {
  group(
    'AdminDepartmentsTest - Pruebas unitarias de administración de departamentos ConVive',
        () {
      test('Administración no permite departamento con título vacío', () {
        print('Validando departamento administrativo con título vacío...');

        final resultado = departamentoAdministrativoValido(
          titulo: '',
          precio: 500,
          ubicacion: 'Avenida 12 de Octubre, Quito',
          estado: 'Pendiente',
          tipo: 'Departamento',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: vacío');
        print('Precio: 500');
        print('Ubicación: Avenida 12 de Octubre, Quito');
        print('Estado: Pendiente');
        print('Tipo: Departamento');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite departamento con precio inválido', () {
        print('Validando departamento administrativo con precio inválido...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Departamento en la Alameda',
          precio: 0,
          ubicacion: 'Avenida 12 de Octubre, Quito',
          estado: 'Pendiente',
          tipo: 'Departamento',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Departamento en la Alameda');
        print('Precio: 0');
        print('Ubicación: Avenida 12 de Octubre, Quito');
        print('Estado: Pendiente');
        print('Tipo: Departamento');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite ubicación vacía', () {
        print('Validando departamento administrativo con ubicación vacía...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          ubicacion: '',
          estado: 'Pendiente',
          tipo: 'Departamento',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Departamento en la Alameda');
        print('Ubicación: vacía');
        print('Estado: Pendiente');
        print('Tipo: Departamento');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite estado inválido', () {
        print('Validando departamento administrativo con estado inválido...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          ubicacion: 'Avenida 12 de Octubre, Quito',
          estado: 'Archivado',
          tipo: 'Departamento',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Departamento en la Alameda');
        print('Estado recibido: Archivado');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite tipo inválido', () {
        print('Validando departamento administrativo con tipo inválido...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          ubicacion: 'Avenida 12 de Octubre, Quito',
          estado: 'Pendiente',
          tipo: 'Local comercial',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Departamento en la Alameda');
        print('Tipo recibido: Local comercial');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración permite departamento válido pendiente de revisión', () {
        print('Validando departamento administrativo válido...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          ubicacion: 'Avenida 12 de Octubre, Quito',
          estado: 'Pendiente',
          tipo: 'Departamento',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Departamento en la Alameda');
        print('Precio: 500');
        print('Ubicación: Avenida 12 de Octubre, Quito');
        print('Estado: Pendiente');
        print('Tipo: Departamento');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Administración permite habitación publicada válida', () {
        print('Validando habitación administrativa válida...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Habitación xd',
          precio: 450,
          ubicacion: 'Avenida Río Amazonas 3123, La Carolina, Quito',
          estado: 'Publicado',
          tipo: 'Habitación',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Habitación xd');
        print('Precio: 450');
        print('Ubicación: Avenida Río Amazonas 3123, La Carolina, Quito');
        print('Estado: Publicado');
        print('Tipo: Habitación');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Administración permite casa publicada válida', () {
        print('Validando casa administrativa válida...');

        final resultado = departamentoAdministrativoValido(
          titulo: 'Casa compartida para estudiantes',
          precio: 700,
          ubicacion: 'Sangolquí, Ecuador',
          estado: 'Publicado',
          tipo: 'Casa',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Propietario/publicador: changoluizajoseph0@gmail.com');
        print('Título: Casa compartida para estudiantes');
        print('Precio: 700');
        print('Ubicación: Sangolquí, Ecuador');
        print('Estado: Publicado');
        print('Tipo: Casa');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
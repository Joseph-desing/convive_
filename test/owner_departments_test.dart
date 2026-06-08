import 'package:flutter_test/flutter_test.dart';

bool validarTituloDetalleDepartamento(String titulo) {
  return titulo.trim().isNotEmpty;
}

bool validarPrecioDetalleDepartamento(double precio) {
  return precio > 0;
}

bool validarDireccionDetalleDepartamento(String direccion) {
  return direccion.trim().isNotEmpty;
}

bool validarDescripcionDetalleDepartamento(String descripcion) {
  return descripcion.trim().length >= 10;
}

bool validarServiciosDepartamento(List<String> servicios) {
  return servicios.isNotEmpty;
}

bool validarPropietarioDepartamento(String propietario) {
  return propietario.trim().isNotEmpty;
}

bool validarCorreoPropietario(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool detalleDepartamentoValido({
  required String titulo,
  required double precio,
  required String direccion,
  required String descripcion,
  required List<String> servicios,
  required String propietario,
  required String correoPropietario,
}) {
  return validarTituloDetalleDepartamento(titulo) &&
      validarPrecioDetalleDepartamento(precio) &&
      validarDireccionDetalleDepartamento(direccion) &&
      validarDescripcionDetalleDepartamento(descripcion) &&
      validarServiciosDepartamento(servicios) &&
      validarPropietarioDepartamento(propietario) &&
      validarCorreoPropietario(correoPropietario);
}

void main() {
  group(
    'DepartmentDetailTest - Pruebas unitarias de información detallada de departamentos ConVive',
        () {
      test('Detalle no permite título vacío', () {
        print('Validando detalle de departamento con título vacío...');

        final resultado = detalleDepartamentoValido(
          titulo: '',
          precio: 500,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: vacío');
        print('Precio: 500');
        print('Dirección: Avenida 12 de Octubre, Quito');
        print('Propietario: Joseph Changoluisa');
        print('Correo propietario: changoluizajoseph0@gmail.com');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle no permite precio inválido', () {
        print('Validando detalle de departamento con precio inválido...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 0,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: Departamento en la Alameda');
        print('Precio: 0');
        print('Dirección: Avenida 12 de Octubre, Quito');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle no permite dirección vacía', () {
        print('Validando detalle de departamento con dirección vacía...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          direccion: '',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: Departamento en la Alameda');
        print('Precio: 500');
        print('Dirección: vacía');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle no permite descripción muy corta', () {
        print('Validando detalle de departamento con descripción corta...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion: 'Bonito',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: Departamento en la Alameda');
        print('Descripción: Bonito');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle no permite lista de servicios vacía', () {
        print('Validando detalle de departamento sin servicios...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: [],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: Departamento en la Alameda');
        print('Servicios: vacío');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle no permite propietario vacío', () {
        print('Validando detalle de departamento con propietario vacío...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: '',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Propietario: vacío');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle no permite correo de propietario inválido', () {
        print('Validando detalle con correo de propietario inválido...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0gmail.com',
        );

        print('Correo propietario: changoluizajoseph0gmail.com');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Detalle permite departamento con información válida', () {
        print('Validando detalle válido de departamento...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 500,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion:
          'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: Departamento en la Alameda');
        print('Precio: 500');
        print('Dirección: Avenida 12 de Octubre, Quito');
        print('Descripción: Departamento cómodo y seguro para estudiantes universitarios.');
        print('Servicios: Internet, Agua, Luz');
        print('Propietario: Joseph Changoluisa');
        print('Correo propietario: changoluizajoseph0@gmail.com');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Detalle permite habitación con información válida', () {
        print('Validando detalle válido de habitación...');

        final resultado = detalleDepartamentoValido(
          titulo: 'Habitación xd',
          precio: 450,
          direccion: 'Avenida Río Amazonas 3123, La Carolina, Quito',
          descripcion:
          'Habitación disponible para estudiante con servicios incluidos.',
          servicios: ['Internet', 'Agua', 'Luz', 'Limpieza'],
          propietario: 'Joseph Changoluisa',
          correoPropietario: 'changoluizajoseph0@gmail.com',
        );

        print('Título: Habitación xd');
        print('Precio: 450');
        print('Dirección: Avenida Río Amazonas 3123, La Carolina, Quito');
        print('Servicios: Internet, Agua, Luz, Limpieza');
        print('Propietario: Joseph Changoluisa');
        print('Correo propietario: changoluizajoseph0@gmail.com');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
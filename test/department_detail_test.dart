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

bool detalleDepartamentoValido({
  required String titulo,
  required double precio,
  required String direccion,
  required String descripcion,
  required List<String> servicios,
}) {
  return validarTituloDetalleDepartamento(titulo) &&
      validarPrecioDetalleDepartamento(precio) &&
      validarDireccionDetalleDepartamento(direccion) &&
      validarDescripcionDetalleDepartamento(descripcion) &&
      validarServiciosDepartamento(servicios);
}

void main() {
  group('DepartmentDetailTest - Pruebas unitarias de información detallada de departamentos', () {
    test('Detalle no permite título vacío', () {
      expect(
        detalleDepartamentoValido(
          titulo: '',
          precio: 450,
          direccion: 'La Carolina, Quito',
          descripcion: 'Departamento cómodo para estudiantes.',
          servicios: ['Internet', 'Agua'],
        ),
        false,
      );
    });

    test('Detalle no permite precio inválido', () {
      expect(
        detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 0,
          direccion: 'Quito',
          descripcion: 'Departamento cómodo para estudiantes.',
          servicios: ['Internet', 'Agua'],
        ),
        false,
      );
    });

    test('Detalle no permite dirección vacía', () {
      expect(
        detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 450,
          direccion: '',
          descripcion: 'Departamento cómodo para estudiantes.',
          servicios: ['Internet', 'Agua'],
        ),
        false,
      );
    });

    test('Detalle no permite descripción muy corta', () {
      expect(
        detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 450,
          direccion: 'Quito',
          descripcion: 'Bonito',
          servicios: ['Internet', 'Agua'],
        ),
        false,
      );
    });

    test('Detalle no permite lista de servicios vacía', () {
      expect(
        detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 450,
          direccion: 'Quito',
          descripcion: 'Departamento cómodo para estudiantes.',
          servicios: [],
        ),
        false,
      );
    });

    test('Detalle permite departamento con información válida', () {
      expect(
        detalleDepartamentoValido(
          titulo: 'Departamento en la Alameda',
          precio: 450,
          direccion: 'Avenida 12 de Octubre, Quito',
          descripcion: 'Departamento cómodo y seguro para estudiantes universitarios.',
          servicios: ['Internet', 'Agua', 'Luz'],
        ),
        true,
      );
    });
  });
}
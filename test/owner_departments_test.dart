import 'package:flutter_test/flutter_test.dart';

bool validarTituloDepartamentoPropietario(String titulo) {
  return titulo.trim().isNotEmpty;
}

bool validarPrecioDepartamentoPropietario(double precio) {
  return precio > 0;
}

bool validarDireccionDepartamentoPropietario(String direccion) {
  return direccion.trim().isNotEmpty;
}

bool validarDisponibilidadDepartamento(String disponibilidad) {
  final disponibilidadesPermitidas = ['Disponible', 'No disponible', 'Reservado'];
  return disponibilidadesPermitidas.contains(disponibilidad);
}

bool validarTipoPublicacionPropietario(String tipo) {
  final tiposPermitidos = ['Departamento', 'Habitación', 'Casa'];
  return tiposPermitidos.contains(tipo);
}

bool departamentoPropietarioValido({
  required String titulo,
  required double precio,
  required String direccion,
  required String disponibilidad,
  required String tipo,
}) {
  return validarTituloDepartamentoPropietario(titulo) &&
      validarPrecioDepartamentoPropietario(precio) &&
      validarDireccionDepartamentoPropietario(direccion) &&
      validarDisponibilidadDepartamento(disponibilidad) &&
      validarTipoPublicacionPropietario(tipo);
}

void main() {
  group('OwnerDepartmentsTest - Pruebas unitarias de gestión de departamentos por el propietario', () {
    test('Propietario no permite departamento con título vacío', () {
      expect(
        departamentoPropietarioValido(
          titulo: '',
          precio: 450,
          direccion: 'Av. Río Amazonas, Quito',
          disponibilidad: 'Disponible',
          tipo: 'Departamento',
        ),
        false,
      );
    });

    test('Propietario no permite departamento con precio inválido', () {
      expect(
        departamentoPropietarioValido(
          titulo: 'Departamento amoblado',
          precio: 0,
          direccion: 'Av. Río Amazonas, Quito',
          disponibilidad: 'Disponible',
          tipo: 'Departamento',
        ),
        false,
      );
    });

    test('Propietario no permite departamento sin dirección', () {
      expect(
        departamentoPropietarioValido(
          titulo: 'Departamento amoblado',
          precio: 450,
          direccion: '',
          disponibilidad: 'Disponible',
          tipo: 'Departamento',
        ),
        false,
      );
    });

    test('Propietario no permite disponibilidad inválida', () {
      expect(
        departamentoPropietarioValido(
          titulo: 'Departamento amoblado',
          precio: 450,
          direccion: 'Av. Río Amazonas, Quito',
          disponibilidad: 'Archivado',
          tipo: 'Departamento',
        ),
        false,
      );
    });

    test('Propietario no permite tipo de publicación inválido', () {
      expect(
        departamentoPropietarioValido(
          titulo: 'Departamento amoblado',
          precio: 450,
          direccion: 'Av. Río Amazonas, Quito',
          disponibilidad: 'Disponible',
          tipo: 'Local comercial',
        ),
        false,
      );
    });

    test('Propietario permite registrar departamento válido', () {
      expect(
        departamentoPropietarioValido(
          titulo: 'Departamento amoblado',
          precio: 450,
          direccion: 'Av. Río Amazonas, Quito',
          disponibilidad: 'Disponible',
          tipo: 'Departamento',
        ),
        true,
      );
    });

    test('Propietario permite registrar habitación válida', () {
      expect(
        departamentoPropietarioValido(
          titulo: 'Habitación para estudiante',
          precio: 180,
          direccion: 'Sangolquí',
          disponibilidad: 'Disponible',
          tipo: 'Habitación',
        ),
        true,
      );
    });
  });
}
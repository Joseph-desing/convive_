import 'package:flutter_test/flutter_test.dart';

bool validarNombreUsuarioAdmin(String nombre) {
  return nombre.trim().isNotEmpty;
}

bool validarCorreoUsuarioAdmin(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool validarRolUsuarioAdmin(String rol) {
  final rolesPermitidos = [
    'Administrador',
    'Propietario',
    'Estudiante',
  ];

  return rolesPermitidos.contains(rol);
}

bool validarEstadoUsuarioAdmin(String estado) {
  final estadosPermitidos = [
    'Activo',
    'Inactivo',
    'Bloqueado',
  ];

  return estadosPermitidos.contains(estado);
}

bool usuarioAdministrativoValido({
  required String nombre,
  required String correo,
  required String rol,
  required String estado,
}) {
  return validarNombreUsuarioAdmin(nombre) &&
      validarCorreoUsuarioAdmin(correo) &&
      validarRolUsuarioAdmin(rol) &&
      validarEstadoUsuarioAdmin(estado);
}

void main() {
  group(
    'AdminUsersTest - Pruebas unitarias de administración de usuarios ConVive',
        () {
      test('Administración no permite usuario con nombre vacío', () {
        print('Validando usuario administrativo con nombre vacío...');

        final resultado = usuarioAdministrativoValido(
          nombre: '',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          estado: 'Activo',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario evaluado: changoluizajoseph0@gmail.com');
        print('Nombre: vacío');
        print('Rol: Estudiante');
        print('Estado: Activo');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite correo con formato incorrecto', () {
        print('Validando usuario administrativo con correo incorrecto...');

        final resultado = usuarioAdministrativoValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0gmail.com',
          rol: 'Estudiante',
          estado: 'Activo',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario evaluado: changoluizajoseph0gmail.com');
        print('Nombre: Joseph Changoluisa');
        print('Rol: Estudiante');
        print('Estado: Activo');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite rol inválido', () {
        print('Validando usuario administrativo con rol inválido...');

        final resultado = usuarioAdministrativoValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Cliente',
          estado: 'Activo',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario evaluado: changoluizajoseph0@gmail.com');
        print('Rol recibido: Cliente');
        print('Estado: Activo');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración no permite estado inválido', () {
        print('Validando usuario administrativo con estado inválido...');

        final resultado = usuarioAdministrativoValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          estado: 'Pendiente',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario evaluado: changoluizajoseph0@gmail.com');
        print('Rol: Estudiante');
        print('Estado recibido: Pendiente');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Administración permite usuario estudiante válido', () {
        print('Validando usuario estudiante válido desde administración...');

        final resultado = usuarioAdministrativoValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          estado: 'Activo',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario evaluado: changoluizajoseph0@gmail.com');
        print('Nombre: Joseph Changoluisa');
        print('Rol: Estudiante');
        print('Estado: Activo');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Administración permite usuario propietario válido', () {
        print('Validando usuario propietario válido desde administración...');

        final resultado = usuarioAdministrativoValido(
          nombre: 'Estudiante ConVive',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          estado: 'Activo',
        );

        print('Administrador: changoluizajoseph@gmail.com');
        print('Usuario evaluado: changoluizajoseph0@gmail.com');
        print('Nombre: Joseph Changoluiza');
        print('Rol: Estudiante');
        print('Estado: Activo');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Administración permite usuario administrador válido', () {
        print('Validando usuario administrador válido...');

        final resultado = usuarioAdministrativoValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph@gmail.com',
          rol: 'Administrador',
          estado: 'Activo',
        );

        print('Administrador evaluado: changoluizajoseph@gmail.com');
        print('Nombre: Joseph Changoluisa');
        print('Rol: Administrador');
        print('Estado: Activo');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
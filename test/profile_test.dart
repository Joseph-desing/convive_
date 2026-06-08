import 'package:flutter_test/flutter_test.dart';

bool validarNombrePerfil(String nombre) {
  return nombre.trim().isNotEmpty;
}

bool validarRolPerfil(String rol) {
  final rolesPermitidos = [
    'Estudiante',
    'Propietario',
    'Administrador',
  ];

  return rolesPermitidos.contains(rol);
}

bool validarCorreoPerfil(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool validarFechaNacimientoPerfil(String fechaNacimiento) {
  return fechaNacimiento.trim().isNotEmpty;
}

bool validarGeneroPerfil(String genero) {
  final generosPermitidos = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decirlo',
  ];

  return generosPermitidos.contains(genero);
}

bool perfilUsuarioValido({
  required String nombre,
  required String correo,
  required String rol,
  required String fechaNacimiento,
  required String genero,
}) {
  return validarNombrePerfil(nombre) &&
      validarCorreoPerfil(correo) &&
      validarRolPerfil(rol) &&
      validarFechaNacimientoPerfil(fechaNacimiento) &&
      validarGeneroPerfil(genero);
}

void main() {
  group(
    'ProfileTest - Pruebas unitarias del perfil de usuario ConVive',
        () {
      test('Perfil no permite nombre vacío', () {
        print('Validando perfil con nombre vacío...');

        final resultado = perfilUsuarioValido(
          nombre: '',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          fechaNacimiento: '2003-06-16',
          genero: 'Masculino',
        );

        print('Nombre: vacío');
        print('Correo: changoluizajoseph0@gmail.com');
        print('Rol: Estudiante');
        print('Fecha de nacimiento: 2003-06-16');
        print('Género: Masculino');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Perfil no permite correo con formato incorrecto', () {
        print('Validando perfil con correo incorrecto...');

        final resultado = perfilUsuarioValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0gmail.com',
          rol: 'Estudiante',
          fechaNacimiento: '2003-06-16',
          genero: 'Masculino',
        );

        print('Nombre: Joseph Changoluisa');
        print('Correo recibido: changoluizajoseph0gmail.com');
        print('Rol: Estudiante');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Perfil no permite rol inválido', () {
        print('Validando perfil con rol inválido...');

        final resultado = perfilUsuarioValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Cliente',
          fechaNacimiento: '2003-06-16',
          genero: 'Masculino',
        );

        print('Nombre: Joseph Changoluisa');
        print('Correo: changoluizajoseph0@gmail.com');
        print('Rol recibido: Cliente');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Perfil no permite fecha de nacimiento vacía', () {
        print('Validando perfil con fecha de nacimiento vacía...');

        final resultado = perfilUsuarioValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          fechaNacimiento: '',
          genero: 'Masculino',
        );

        print('Nombre: Joseph Changoluisa');
        print('Correo: changoluizajoseph0@gmail.com');
        print('Fecha de nacimiento: vacía');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Perfil no permite género inválido', () {
        print('Validando perfil con género inválido...');

        final resultado = perfilUsuarioValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          fechaNacimiento: '2003-06-16',
          genero: 'No definido',
        );

        print('Nombre: Joseph Changoluisa');
        print('Correo: changoluizajoseph0@gmail.com');
        print('Género recibido: No definido');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Perfil permite datos válidos de estudiante', () {
        print('Validando perfil válido de estudiante...');

        final resultado = perfilUsuarioValido(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph0@gmail.com',
          rol: 'Estudiante',
          fechaNacimiento: '2003-06-16',
          genero: 'Masculino',
        );

        print('Nombre: Joseph Changoluisa');
        print('Correo: changoluizajoseph0@gmail.com');
        print('Rol: Estudiante');
        print('Fecha de nacimiento: 2003-06-16');
        print('Género: Masculino');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Perfil permite datos válidos de propietario', () {
        print('Validando perfil válido de propietario...');

        final resultado = perfilUsuarioValido(
          nombre: 'Propietario ConVive',
          correo: 'propietario@convive.com',
          rol: 'Propietario',
          fechaNacimiento: '1998-04-12',
          genero: 'Masculino',
        );

        print('Nombre: Propietario ConVive');
        print('Correo: propietario@convive.com');
        print('Rol: Propietario');
        print('Fecha de nacimiento: 1998-04-12');
        print('Género: Masculino');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Perfil permite datos válidos de administrador', () {
        print('Validando perfil válido de administrador...');

        final resultado = perfilUsuarioValido(
          nombre: 'Administrador ConVive',
          correo: 'admin@convive.com',
          rol: 'Administrador',
          fechaNacimiento: '1995-01-01',
          genero: 'Prefiero no decirlo',
        );

        print('Nombre: Administrador ConVive');
        print('Correo: admin@convive.com');
        print('Rol: Administrador');
        print('Fecha de nacimiento: 1995-01-01');
        print('Género: Prefiero no decirlo');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
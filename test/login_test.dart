import 'package:flutter_test/flutter_test.dart';

bool validarCorreoLogin(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool validarPasswordLogin(String password) {
  return password.length >= 6;
}

bool puedeIniciarSesion(String correo, String password) {
  return validarCorreoLogin(correo) && validarPasswordLogin(password);
}

void main() {
  group(
    'LoginTest - Pruebas unitarias de inicio de sesión ConVive',
        () {
      test('Login no permite correo vacío', () {
        print('Validando inicio de sesión con correo vacío...');

        final resultado = puedeIniciarSesion('', '16062003');

        print('Usuario: correo vacío');
        print('Contraseña: 16062003');
        print('Módulo: Inicio de sesión');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Login no permite correo con formato incorrecto', () {
        print('Validando inicio de sesión con correo incorrecto...');

        final resultado = puedeIniciarSesion(
          'changoluizajoseph0gmail.com',
          '16062003',
        );

        print('Usuario: changoluizajoseph0gmail.com');
        print('Contraseña: 16062003');
        print('Módulo: Inicio de sesión');
        print('Validación: formato de correo electrónico');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Login no permite contraseña vacía', () {
        print('Validando inicio de sesión con contraseña vacía...');

        final resultado = puedeIniciarSesion(
          'changoluizajoseph0@gmail.com',
          '',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Contraseña: vacía');
        print('Módulo: Inicio de sesión');
        print('Validación: campo contraseña obligatorio');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Login no permite contraseña menor a 6 caracteres', () {
        print('Validando inicio de sesión con contraseña corta...');

        final resultado = puedeIniciarSesion(
          'changoluizajoseph0@gmail.com',
          '12345',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Contraseña: 12345');
        print('Módulo: Inicio de sesión');
        print('Validación: longitud mínima de contraseña');
        print('Resultado esperado: false');
        print('Resultado obtenido: $resultado');

        expect(resultado, false);
      });

      test('Login permite iniciar sesión con correo y contraseña válidos', () {
        print('Validando inicio de sesión con credenciales válidas...');

        final resultado = puedeIniciarSesion(
          'changoluizajoseph0@gmail.com',
          '16062003',
        );

        print('Usuario: changoluizajoseph0@gmail.com');
        print('Contraseña: 16062003');
        print('Módulo: Inicio de sesión');
        print('Validación: credenciales con formato correcto');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });

      test('Login permite validar correo institucional o personal válido', () {
        print('Validando correo personal válido para inicio de sesión...');

        final resultado = validarCorreoLogin('changoluizajoseph0@gmail.com');

        print('Correo evaluado: changoluizajoseph0@gmail.com');
        print('Módulo: Inicio de sesión');
        print('Resultado esperado: true');
        print('Resultado obtenido: $resultado');

        expect(resultado, true);
      });
    },
  );
}
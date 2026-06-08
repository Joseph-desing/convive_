import 'package:flutter_test/flutter_test.dart';

bool validarCorreoRecuperacion(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool validarNuevaPassword(String password) {
  return password.length >= 6;
}

bool validarConfirmacionPassword(String password, String confirmPassword) {
  return password == confirmPassword;
}

bool puedeEnviarCorreoRecuperacion(String correo) {
  return validarCorreoRecuperacion(correo);
}

bool puedeCambiarPassword({
  required String password,
  required String confirmPassword,
  required bool enlaceValido,
}) {
  return enlaceValido &&
      validarNuevaPassword(password) &&
      validarConfirmacionPassword(password, confirmPassword);
}

void main() {
  group(
    'ResetPasswordTest - Pruebas unitarias de recuperación de contraseña ConVive',
        () {
      test('Recuperación no permite correo vacío', () {
        print('Validando recuperación con correo vacío...');
        final resultado = puedeEnviarCorreoRecuperacion('');
        print('Resultado esperado: false | Resultado obtenido: $resultado');
        expect(resultado, false);
      });

      test('Recuperación no permite correo con formato incorrecto', () {
        print('Validando recuperación con correo incorrecto: josephgmail.com');
        final resultado = puedeEnviarCorreoRecuperacion('josephgmail.com');
        print('Resultado esperado: false | Resultado obtenido: $resultado');
        expect(resultado, false);
      });

      test('Recuperación permite correo con formato válido', () {
        print('Validando recuperación con correo válido: changoluizajoseph@gmail.com');
        final resultado =
        puedeEnviarCorreoRecuperacion('changoluizajoseph@gmail.com');
        print('Resultado esperado: true | Resultado obtenido: $resultado');
        expect(resultado, true);
      });

      test('Cambio de contraseña no permite enlace inválido', () {
        print('Validando cambio de contraseña con enlace inválido...');
        final resultado = puedeCambiarPassword(
          password: '16062003',
          confirmPassword: '16062003',
          enlaceValido: false,
        );
        print('Resultado esperado: false | Resultado obtenido: $resultado');
        expect(resultado, false);
      });

      test('Cambio de contraseña no permite contraseña menor a 6 caracteres', () {
        print('Validando contraseña menor a 6 caracteres...');
        final resultado = puedeCambiarPassword(
          password: '12345',
          confirmPassword: '12345',
          enlaceValido: true,
        );
        print('Resultado esperado: false | Resultado obtenido: $resultado');
        expect(resultado, false);
      });

      test('Cambio de contraseña no permite contraseñas diferentes', () {
        print('Validando contraseñas diferentes...');
        final resultado = puedeCambiarPassword(
          password: '16062003',
          confirmPassword: '123456',
          enlaceValido: true,
        );
        print('Resultado esperado: false | Resultado obtenido: $resultado');
        expect(resultado, false);
      });

      test('Cambio de contraseña permite datos válidos y enlace válido', () {
        print('Validando cambio con datos válidos y enlace válido...');
        final resultado = puedeCambiarPassword(
          password: '16062003',
          confirmPassword: '16062003',
          enlaceValido: true,
        );
        print('Resultado esperado: true | Resultado obtenido: $resultado');
        expect(resultado, true);
      });
    },
  );
}
import 'package:flutter_test/flutter_test.dart';

bool validarCorreoRegistro(String correo) {
  return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo);
}

bool validarPasswordRegistro(String password) {
  return password.length >= 6;
}

bool validarNombreRegistro(String nombre) {
  return nombre.trim().isNotEmpty;
}

bool validarConfirmacionPassword(String password, String confirmPassword) {
  return password == confirmPassword;
}

bool puedeRegistrarse({
  required String nombre,
  required String correo,
  required String password,
  required String confirmPassword,
}) {
  return validarNombreRegistro(nombre) &&
      validarCorreoRegistro(correo) &&
      validarPasswordRegistro(password) &&
      validarConfirmacionPassword(password, confirmPassword);
}

void main() {
  group('RegisterTest - Pruebas unitarias de registro de usuarios', () {
    test('Registro no permite nombre vacío', () {
      expect(
        puedeRegistrarse(
          nombre: '',
          correo: 'changoluizajoseph@gmail.com',
          password: '16062003',
          confirmPassword: '16062003',
        ),
        false,
      );
    });

    test('Registro no permite correo vacío', () {
      expect(
        puedeRegistrarse(
          nombre: 'Joseph Changoluisa',
          correo: '',
          password: '16062003',
          confirmPassword: '16062003',
        ),
        false,
      );
    });

    test('Registro no permite correo con formato incorrecto', () {
      expect(
        puedeRegistrarse(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajosephgmail.com',
          password: '16062003',
          confirmPassword: '16062003',
        ),
        false,
      );
    });

    test('Registro no permite contraseña menor a 6 caracteres', () {
      expect(
        puedeRegistrarse(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph@gmail.com',
          password: '12345',
          confirmPassword: '12345',
        ),
        false,
      );
    });

    test('Registro no permite contraseñas diferentes', () {
      expect(
        puedeRegistrarse(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph@gmail.com',
          password: '16062003',
          confirmPassword: '123456',
        ),
        false,
      );
    });

    test('Registro permite crear usuario con datos válidos', () {
      expect(
        puedeRegistrarse(
          nombre: 'Joseph Changoluisa',
          correo: 'changoluizajoseph@gmail.com',
          password: '16062003',
          confirmPassword: '16062003',
        ),
        true,
      );
    });
  });
}
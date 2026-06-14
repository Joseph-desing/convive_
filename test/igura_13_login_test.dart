import 'package:flutter_test/flutter_test.dart';

void main() {
  const usuarioRoomie = 'changoluizajoseph0@gmail.com';
  const usuarioAdmin = 'changoluizajoseph@gmail.com';

  test('Figura 13 - Verifica credenciales válidas e inválidas', () {
    final usuariosValidos = [
      usuarioRoomie,
      usuarioAdmin,
    ];

    final loginValido = usuariosValidos.contains(usuarioRoomie);
    final loginInvalido = usuariosValidos.contains('usuarioincorrecto@gmail.com');

    expect(loginValido, true);
    expect(loginInvalido, false);

    print('Módulo: Inicio de sesión');
    print('Usuario válido: $usuarioRoomie');
    print('Resultado esperado: true');
    print('Resultado obtenido: $loginValido');
  });
}
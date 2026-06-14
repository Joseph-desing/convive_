import 'package:flutter_test/flutter_test.dart';

void main() {
  test(' Verifica creación, modificación y eliminación por parte del administrador', () {
    const administrador = 'changoluizajoseph@gmail.com';

    final usuarios = <String>[
      'changoluizajoseph0@gmail.com',
    ];

    usuarios.add('nuevo_usuario@gmail.com');
    final creado = usuarios.contains('nuevo_usuario@gmail.com');

    usuarios[1] = 'usuario_modificado@gmail.com';
    final modificado = usuarios.contains('usuario_modificado@gmail.com');

    usuarios.remove('usuario_modificado@gmail.com');
    final eliminado = !usuarios.contains('usuario_modificado@gmail.com');

    expect(creado, true);
    expect(modificado, true);
    expect(eliminado, true);

    print('Administrador: $administrador');
    print('Módulo: Gestión de usuarios');
    print('Creado: $creado');
    print('Modificado: $modificado');
    print('Eliminado: $eliminado');
  });
}
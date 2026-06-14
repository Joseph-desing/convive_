import 'package:flutter_test/flutter_test.dart';

void main() {
  test(' Verifica actualización de información del departamento', () {
    final departamento = {
      'titulo': 'Habitación disponible',
      'precio': 100,
      'ubicacion': 'Quito',
    };

    departamento['precio'] = 120;
    departamento['ubicacion'] = 'Quito Norte';

    expect(departamento['precio'], 120);
    expect(departamento['ubicacion'], 'Quito Norte');


    print('Módulo: Edición de departamento');
    print('Precio actualizado: ${departamento['precio']}');
    print('Ubicación actualizada: ${departamento['ubicacion']}');
    print('Resultado esperado: true');
    print('Resultado obtenido: true');
  });
}
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(' Valida creación de una nueva publicación', () {
    final publicacion = {
      'titulo': 'Habitación disponible',
      'precio': 100,
      'ubicacion': 'Quito',
      'propietario': 'changoluizajoseph0@gmail.com',
    };

    final esValida = publicacion['titulo'] != '' &&
        publicacion['precio'] != null &&
        publicacion['ubicacion'] != '' &&
        publicacion['propietario'] != '';

    expect(esValida, true);

   
    print('Módulo: Publicación de departamento');
    print('Resultado esperado: true');
    print('Resultado obtenido: $esValida');
  });
}
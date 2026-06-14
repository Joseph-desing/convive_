import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verifica que se generen recomendaciones según preferencias del usuario', () {
    final preferencias = {
      'presupuesto': 120,
      'ubicacion': 'Quito',
      'tipo': 'Habitación',
    };

    final departamentos = [
      {
        'titulo': 'Habitación cerca de la universidad',
        'precio': 100,
        'ubicacion': 'Quito',
        'tipo': 'Habitación',
      },
      {
        'titulo': 'Departamento completo',
        'precio': 300,
        'ubicacion': 'Sangolquí',
        'tipo': 'Departamento',
      },
    ];

    final recomendados = departamentos.where((d) {
      final precioDepartamento = d['precio'] as int;
      final presupuestoUsuario = preferencias['presupuesto'] as int;

      return precioDepartamento <= presupuestoUsuario &&
          d['ubicacion'] == preferencias['ubicacion'] &&
          d['tipo'] == preferencias['tipo'];
    }).toList();

    expect(recomendados.isNotEmpty, true);

    print('Módulo: Sistema de recomendación');
    print('Recomendaciones encontradas: ${recomendados.length}');
    print('Resultado esperado: true');
    print('Resultado obtenido: ${recomendados.isNotEmpty}');
  });
}
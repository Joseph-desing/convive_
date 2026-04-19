import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../providers/auth_provider.dart';
import '../models/property.dart';
import '../config/supabase_provider.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> _properties = [];
  List<dynamic> _filteredProperties = [];
  List<Map<String, dynamic>> _users = []; // Lista de usuarios únicos
  List<Map<String, dynamic>> _filteredUsers = []; // Usuarios filtrados
  bool _isLoading = false;
  bool _isSearching = false;
  String? _selectedPropertyId;
  String? _selectedUserId; // Usuario seleccionado
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'property'; // 'property' o 'roommate'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    Future.microtask(() {
      if (mounted) {
        _loadProperties();
      }
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      
      // Primero filtra por tipo
      List<Map<String, dynamic>> typeFiltered = _users;
      if (_searchType != 'all') {
        typeFiltered = _users.where((user) {
          final userType = user['type']?.toString() ?? 'property';
          if (userType == 'both') {
            // Si tiene ambos, incluir en todos los filtros
            return true;
          }
          return _searchType == 'property'
              ? userType == 'property'
              : userType == 'roommate';
        }).toList();
      }
      
      // Luego filtra por búsqueda
      if (query.isEmpty) {
        _filteredUsers = typeFiltered;
      } else {
        _filteredUsers = typeFiltered.where((user) {
          final name = (user['owner_name']?.toString() ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      // Cargar propiedades
      final propertiesResponse = await SupabaseProvider.client
          .from('properties')
          .select()
          .limit(50);

      final allItems = <dynamic>[];
      final userIds = <String>{};

      // Recolectar todos los user_ids
      if (propertiesResponse is List) {
        for (var p in propertiesResponse) {
          if (p is Map) {
            final userId = p['owner_id']?.toString() ?? 
                          p['user_id']?.toString() ?? 
                          p['created_by']?.toString();
            if (userId != null && userId.isNotEmpty) {
              userIds.add(userId);
            }
          }
        }
      }

      // Intentar cargar roommate_searches
      try {
        final roommatesResponse = await SupabaseProvider.client
            .from('roommate_searches')
            .select()
            .limit(50);

        if (roommatesResponse is List) {
          for (var r in roommatesResponse) {
            if (r is Map) {
              final userId = r['owner_id']?.toString() ?? 
                            r['user_id']?.toString() ?? 
                            r['created_by']?.toString();
              if (userId != null && userId.isNotEmpty) {
                userIds.add(userId);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Nota: roommate_searches: $e');
      }

      // Cargar nombres y fotos de usuarios desde profile y users
      final userNames = <String, String>{};
      final userImages = <String, String>{};
      if (userIds.isNotEmpty) {
        try {
          // Primero cargar desde profiles donde está el nombre completo y foto
          final profileResponse = await SupabaseProvider.client
              .from('profiles')
              .select('user_id, full_name, profile_image_url');

          if (profileResponse is List) {
            for (var p in profileResponse) {
              if (p is Map) {
                final userId = p['user_id']?.toString() ?? '';
                final fullName = p['full_name']?.toString().trim() ?? '';
                final imageUrl = p['profile_image_url']?.toString().trim() ?? '';
                
                if (userIds.contains(userId)) {
                  if (fullName.isNotEmpty) {
                    userNames[userId] = fullName;
                  }
                  if (imageUrl.isNotEmpty) {
                    userImages[userId] = imageUrl;
                  }
                }
              }
            }
          }

          // Cargar también de users para completar los que no están en profiles
          final usersResponse = await SupabaseProvider.client
              .from('users')
              .select('id, full_name, email');

          if (usersResponse is List) {
            for (var u in usersResponse) {
              if (u is Map) {
                final id = u['id']?.toString() ?? '';
                final fullName = u['full_name']?.toString().trim() ?? '';
                final email = u['email']?.toString().trim() ?? '';
                
                if (userIds.contains(id) && !userNames.containsKey(id)) {
                  // Usar full_name si existe y no está vacío, sino email, sino id
                  final displayName = fullName.isNotEmpty ? fullName : 
                                     email.isNotEmpty ? email : id;
                  userNames[id] = displayName;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error cargando nombres de usuarios: $e');
        }

        // Para usuarios que no están en la tabla users, generar nombre legible
        for (var userId in userIds) {
          if (!userNames.containsKey(userId)) {
            // Generar nombre basado en primeros caracteres del UUID
            final shortId = userId.substring(0, 8).toUpperCase();
            userNames[userId] = 'Usuario $shortId';
          }
        }
      }

      // Procesar propiedades
      if (propertiesResponse is List) {
        for (var p in propertiesResponse) {
          if (p is Map) {
            final userId = p['owner_id']?.toString() ?? 
                          p['user_id']?.toString() ?? 
                          p['created_by']?.toString() ?? 
                          'Desconocido';
            final displayName = userNames[userId] ?? userId;
            
            allItems.add({
              'id': p['id']?.toString() ?? '',
              'title': p['title']?.toString() ?? 'Sin título',
              'description': p['description']?.toString() ?? '',
              'price': p['price'],
              'owner_name': displayName,
              'user_id': userId,
              'type': 'property',
            });
          }
        }
      }

      // Procesar roommate_searches
      try {
        final roommatesResponse = await SupabaseProvider.client
            .from('roommate_searches')
            .select()
            .limit(50);

        if (roommatesResponse is List) {
          for (var r in roommatesResponse) {
            if (r is Map) {
              final userId = r['owner_id']?.toString() ?? 
                            r['user_id']?.toString() ?? 
                            r['created_by']?.toString() ?? 
                            'Desconocido';
              final displayName = userNames[userId] ?? userId;
              
              allItems.add({
                'id': r['id']?.toString() ?? '',
                'title': r['title']?.toString() ?? 'Sin título',
                'description': r['description']?.toString() ?? '',
                'price': null,
                'owner_name': displayName,
                'user_id': userId,
                'type': 'roommate',
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Nota: roommate_searches: $e');
      }

      // Extraer usuarios únicos
      final usersMap = <String, Map<String, dynamic>>{};
      
      // Obtener el ID del usuario actual
      final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
      
      for (var item in allItems) {
        final userName = item['owner_name']?.toString() ?? 'Desconocido';
        final itemType = item['type'] ?? 'property';
        final userId = item['user_id']?.toString() ?? '';
        
        // NO incluir al usuario actual en la lista
        if (userId == currentUserId) {
          continue;
        }
        
        if (!usersMap.containsKey(userName)) {
          usersMap[userName] = {
            'owner_name': userName,
            'user_id': userId,
            'type': itemType,
            'profile_image_url': userImages[userId] ?? '',
          };
        } else if (usersMap[userName]!['type'] != 'both') {
          usersMap[userName]!['type'] = 'both';
        }
      }

      setState(() {
        _properties = allItems;
        _users = usersMap.values.toList();
        _filteredUsers = _users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedPropertyId == null || _selectedUserId == null || _complaintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un usuario, propiedad y escribe tu queja')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes estar autenticado')),
      );
      return;
    }

    try {
      // Obtener info de la propiedad seleccionada
      final selectedProperty = _properties.firstWhere(
        (prop) {
          if (prop is! Map) return false;
          final propId = prop['id']?.toString() ?? '';
          return propId == _selectedPropertyId;
        },
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;

      final title = selectedProperty['title']?.toString() ?? 'Sin título';
      final reportedUserName = _users.firstWhere(
        (u) => u['user_id'] == _selectedUserId,
        orElse: () => {'owner_name': 'Usuario desconocido'},
      )['owner_name']?.toString() ?? 'Usuario desconocido';

      // Construir el mensaje completo con la información
      final completeMessage = '''
Propiedad/Búsqueda: $title
Usuario reportado: $reportedUserName

Descripción de la queja:
${_complaintController.text}
      '''.trim();

      await SupabaseProvider.client.from('feedback').insert({
        'user_id': authProvider.currentUser!.id,
        'type': 'complaint',
        'status': 'open',
        'subject': 'Queja: $title',
        'message': completeMessage,
        'category': 'property_complaint',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Queja enviada al administrador'),
            backgroundColor: Colors.green,
          ),
        );
        _complaintController.clear();
        setState(() {
          _selectedPropertyId = null;
          _selectedUserId = null;
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Quejas'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtros
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _searchType,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            prefixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'property',
                              child: Row(
                                children: const [
                                  Icon(Icons.apartment, size: 18),
                                  SizedBox(width: 8),
                                  Text('Departamento'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'roommate',
                              child: Row(
                                children: const [
                                  Icon(Icons.people, size: 18),
                                  SizedBox(width: 8),
                                  Text('Rommi'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'all',
                              child: Row(
                                children: const [
                                  Icon(Icons.list, size: 18),
                                  SizedBox(width: 8),
                                  Text('Todos'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchType = value ?? 'property';
                              _filterUsers();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buscador
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterUsers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Busca y selecciona un usuario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de usuarios filtrados
                  if (_filteredUsers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _isSearching
                              ? 'No se encontraron usuarios'
                              : 'No hay usuarios disponibles',
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index] as Map<String, dynamic>;
                        final ownerName = user['owner_name']?.toString() ?? 'Anónimo';
                        final userId = user['user_id']?.toString() ?? '';
                        final isSelected = _selectedUserId == userId;
                        final userType = (user['type'] ?? 'property').toString();

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserId = userId;
                              _selectedPropertyId = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    image: (user['profile_image_url']?.toString() ?? '').isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(user['profile_image_url']?.toString() ?? ''),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (user['profile_image_url']?.toString() ?? '').isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ownerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        userType == 'both'
                                            ? 'Depto + Rommi'
                                            : userType == 'roommate'
                                                ? 'Busca Rommi'
                                                : 'Publica Depto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Mostrar propiedades del usuario seleccionado
                  if (_selectedUserId != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Selecciona qué reportar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._properties
                        .where((prop) {
                          if (prop is! Map) return false;
                          final propUserId = (prop['user_id'] ?? '').toString();
                          final propType = (prop['type'] ?? 'property').toString();
                          
                          // Filtrar por usuario ID
                          if (propUserId != _selectedUserId) return false;
                          
                          // Filtrar por tipo si está seleccionado
                          if (_searchType == 'all') return true;
                          
                          if (_searchType == 'property') {
                            return propType == 'property';
                          } else if (_searchType == 'roommate') {
                            return propType == 'roommate';
                          }
                          return true;
                        })
                        .map((item) {
                      final itemMap = item as Map<String, dynamic>;
                      final isSelected = _selectedPropertyId == itemMap['id'];
                      final type = (itemMap['type'] ?? 'property').toString();

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPropertyId = itemMap['id']);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.05)
                                : Colors.transparent,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    type == 'roommate'
                                        ? Icons.people
                                        : Icons.apartment,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      itemMap['title']?.toString() ?? 'Sin título',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                itemMap['description']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (itemMap['price'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '\$${itemMap['price']}/mes',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Describe tu queja',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _complaintController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Cuéntanos qué pasó...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enviar Queja al Administrador',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

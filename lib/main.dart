import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Para realizar peticiones HTTP
import 'dart:convert'; // Para decodificar el JSON

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // LLamada a la API para obtener la lista de pokemons
  Future<Map<String, dynamic>> getListPokemon(int limit) async {
    final urlList = Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=$limit'); // URL de la API
    try {
      final response =
          await http.get(urlList); // Realizamos la petición GET a la API
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      return <String, dynamic>{'results': []};
    }
  }

  // Llamada a la API para obtener los datos de un pokemon
  Future<Map<String, dynamic>> getPokemon(String name) async {
    final urlPokemon =
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'); // URL de la API
    try {
      final response =
          await http.get(urlPokemon); // Realizamos la petición GET a la API
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data');
    }
  }

  // Obtener un pokemon por url
  Future<Map<String, dynamic>> getPokemonByUrl(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)); // Realizamos la petición GET a la API
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data');
    }
  }

  Future<List<String>> getCatFacts(int count, String lang) async {
    final url = Uri.https('meowfacts.herokuapp.com', '/', {
      'count': '$count',
      'lang': lang,
    });

    try {
      // Realizamos la petición GET a la API
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final _datos = jsonDecode(response.body)
            as Map<String, dynamic>; // Decodificamos el JSON

        // Extraer la lista de datos de "data"
        final List<String> catFacts = List<String>.from(_datos['data']);
        // Retornar los datos
        return catFacts;
      } else {
        throw Exception('Error al obtener los datos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.red,
        ).copyWith(secondary: Colors.red),
      ),
      home: const MyHomePage(title: 'Pokedex'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var frameSeleccionado = 0; // indice del frame seleccionado
  // Inicializamos la lista de pokemons

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (frameSeleccionado) {
      case 0:
        // Página de generador de palabras.
        page = PokemonScreen();
        break;
      case 1:
        // Página de favoritos.
        page = CatFactsScreen();
        break;
      default:
        // Si no se selecciona ninguna pestaña, lanzar un error.
        throw UnimplementedError('no widget for $frameSeleccionado');
    }

    // En este metodo se construye la interfaz de la aplicación
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth > 600, // Extender la barra de navegación si el ancho es mayor a 600.
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.pets),
                      label: Text(
                        'Pokedex',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pets),
                      label: Text(
                        'Cats Facts',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  selectedIndex: frameSeleccionado, // Índice de la pestaña seleccionada.
                  onDestinationSelected: (value) {
                    print('selected: $value');
                    setState(() {
                      // Actualizar el índice de la pestaña seleccionada.
                      frameSeleccionado = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page, // Mostrar la página seleccionada.
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  late Future<Map<String, dynamic>>
      _listPokemon; // Variable para almacenar la lista de pokemons
  final TextEditingController _nombrePokemonController =
      TextEditingController(); // Controlador para el campo de texto
  final TextEditingController _limitesController =
      TextEditingController(); // Controlador para el campo de texto
  int _limit = 10; // Limite de pokemons a mostrar

  // Inicializamos la lista de pokemons
  @override
  void initState() {
    super.initState();
    _loadPokemonList();
  }

  void _loadPokemonList() {
    setState(() {
      _listPokemon = MyApp().getListPokemon(_limit);
    });
  }

  void _searchPokemon(String name) async {
    try {
      // Obtenemos los detalles del Pokémon
      final pokemonDetails = await MyApp().getPokemon(name);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(pokemonDetails['name'].toUpperCase()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  pokemonDetails['sprites']['front_default'] ?? '',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons
                        .error); // Mostrar icono de error si no se puede cargar la imagen
                  },
                ),
                const SizedBox(height: 10),
                Text('Altura: ${pokemonDetails['height']}'),
                Text('Peso: ${pokemonDetails['weight']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Mostrar error si el Pokémon no se encuentra
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error), // Icono de error
                Text('No se encontró el Pokémon.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokedex'),
      ),
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombrePokemonController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar Pokémon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final searchTerm =
                        _nombrePokemonController.text.trim().toLowerCase();
                    if (searchTerm.isNotEmpty) {
                      _searchPokemon(searchTerm);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _limitesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de Pokémon a listar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    final newLimit =
                        int.tryParse(_limitesController.text.trim());
                    if (newLimit != null && newLimit > 0) {
                      setState(() {
                        _limit = newLimit;
                      });
                      _loadPokemonList();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _listPokemon,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final pokemonData = snapshot.data!;
                  final results = pokemonData['results'] as List;

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final pokemon = results[index];
                      return ListTile(
                        title: Text('${index + 1}: ${pokemon["name"]}'),
                        onTap: () async {
                          final pokemonDetails =
                              await MyApp().getPokemonByUrl(pokemon['url']);
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title:
                                    Text(pokemonDetails['name'].toUpperCase()),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      pokemonDetails['sprites']
                                              ['front_default'] ??
                                          '',
                                      width: 100,
                                      height: 100,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Text(
                                            'No se pudo cargar la imagen');
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Text('Altura: ${pokemonDetails['height']}'),
                                    Text('Peso: ${pokemonDetails['weight']}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No se encontraron datos.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CatFactsScreen extends StatefulWidget {
  const CatFactsScreen({super.key});

  @override
  _CatFactsScreenState createState() => _CatFactsScreenState();
}

class _CatFactsScreenState extends State<CatFactsScreen> {
  late Future<List<String>> _catFacts;

  @override
  void initState() {
    super.initState();
    // Llamamos al método para obtener los hechos sobre gatos
    _catFacts = MyApp().getCatFacts(10, 'es'); // Obtener 10 hechos en español
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hechos sobre Gatos'),
      ),
      body: FutureBuilder<List<String>>(
        future: _catFacts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Cargando
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Error
          } else if (snapshot.hasData) {
            final facts = snapshot.data!; // Datos obtenidos
            return ListView.builder(
              itemCount: facts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(facts[index]), // Mostramos cada hecho
                  leading: const Icon(Icons.pets), // Ícono decorativo
                );
              },
            );
          } else {
            return const Center(child: Text('No se encontraron datos.'));
          }
        },
      ),
    );
  }
}

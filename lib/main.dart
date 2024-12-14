import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Para realizar peticiones HTTP
import 'dart:convert'; // Para decodificar el JSON

void main() {
  runApp(const MyApp());
}

class PokemonService {
  final http.Client client;

  PokemonService(this.client);

  Future<Map<String, dynamic>> getListPokemon(int limit) async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limit');
    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener la lista de Pokémon');
      }
    } catch (e) {
      return {'results': []};
    }
  }

  Future<Map<String, dynamic>> getPokemon(String name) async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener datos del Pokémon');
      }
    } catch (e) {
      throw Exception('Error al obtener datos del Pokémon: $e');
    }
  }

  Future<List<String>> getCatFacts(int count, String lang) async {
    final url = Uri.https('meowfacts.herokuapp.com', '/', {
      'count': '$count',
      'lang': lang,
    });

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['data']);
      } else {
        throw Exception('Error al obtener los datos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex',
      theme: ThemeData(
        primarySwatch: Colors.red,
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
  int selectedFrame = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedFrame) {
      case 0:
        page = PokemonScreen();
        break;
      case 1:
        page = CatFactsScreen();
        break;
      default:
        throw UnimplementedError('No widget for $selectedFrame');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth > 600,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.pets),
                    label: Text('Pokedex'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.info),
                    label: Text('Cat Facts'),
                  ),
                ],
                selectedIndex: selectedFrame,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedFrame = value;
                  });
                },
              ),
            ),
            Expanded(
              child: page,
            ),
          ],
        ),
      );
    });
  }
}

class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  late Future<Map<String, dynamic>> _pokemonListFuture;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  int _limit = 10;
  final PokemonService _pokemonService = PokemonService(http.Client());

  @override
  void initState() {
    super.initState();
    _loadPokemonList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _loadPokemonList() {
    setState(() {
      _pokemonListFuture = _pokemonService.getListPokemon(_limit);
    });
  }

  void _searchPokemon(String name) async {
    try {
      final pokemonDetails = await _pokemonService.getPokemon(name);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(pokemonDetails['name'].toUpperCase()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                pokemonDetails['sprites']['front_default'] ?? '',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
        ),
      );
    } catch (e) {
      _showError('No se encontró el Pokémon.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokedex'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar Pokémon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final searchTerm = _searchController.text.trim().toLowerCase();
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
                    controller: _limitController,
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
                    final newLimit = int.tryParse(_limitController.text.trim());
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
              future: _pokemonListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final results = snapshot.data!['results'] as List;

                  if (results.isEmpty) {
                    return const Center(child: Text('No se encontraron Pokémon.'));
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final pokemon = results[index];
                      return ListTile(
                        title: Text('${index + 1}: ${pokemon["name"]}'),
                        onTap: () => _searchPokemon(pokemon['name']),
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
  late Future<List<String>> _catFactsFuture;
  final PokemonService _pokemonService = PokemonService(http.Client());

  @override
  void initState() {
    super.initState();
    _catFactsFuture = _pokemonService.getCatFacts(10, 'esp'); // 10 hechos en español
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hechos sobre Gatos'),
      ),
      body: FutureBuilder<List<String>>(
        future: _catFactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final facts = snapshot.data!;

            return ListView.builder(
              itemCount: facts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(facts[index]),
                leading: const Icon(Icons.pets),
              ),
            );
          } else {
            return const Center(child: Text('No se encontraron datos.'));
          }
        },
      ),
    );
  }
}

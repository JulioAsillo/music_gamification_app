import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Riverpod 3: StateProvider/StateNotifier viven aquí
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/tracks_provider.dart';

/// Enum para tipos de filtro
enum FilterType {
  genre,
  artist,
  album,
}

/// Enum para tipo de ordenamiento
enum SortType {
  nameAsc,
  nameDesc,
  dateAdded,
  mostPlayed,
  duration,
}

/// Provider para el tipo de ordenamiento actual
final sortTypeProvider = StateProvider<SortType>((ref) => SortType.nameAsc);

/// Provider para el filtro actual (ahora soporta múltiples valores)
final currentFilterProvider = StateProvider<Map<FilterType, List<String>>>((ref) {
  return {
    FilterType.genre: [],
    FilterType.artist: [],
    FilterType.album: [],
  };
});

/// Pantalla de filtros y ordenamiento
class FiltersScreen extends ConsumerWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortType = ref.watch(sortTypeProvider);
    final currentFilter = ref.watch(currentFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Filtros y Ordenamiento',
          style: AppTextStyles.heading2(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Limpiar todos los filtros
              ref.read(currentFilterProvider.notifier).state = {
                FilterType.genre: [],
                FilterType.artist: [],
                FilterType.album: [],
              };
              ref.read(sortTypeProvider.notifier).state = SortType.nameAsc;
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Ordenamiento
            _buildSection(
              context,
              'Ordenar por',
              Icons.sort,
              Column(
                children: [
                  _buildSortOption(
                    context,
                    ref,
                    'Nombre (A-Z)',
                    SortType.nameAsc,
                    sortType,
                    Icons.sort_by_alpha,
                  ),
                  _buildSortOption(
                    context,
                    ref,
                    'Nombre (Z-A)',
                    SortType.nameDesc,
                    sortType,
                    Icons.sort_by_alpha,
                  ),
                  _buildSortOption(
                    context,
                    ref,
                    'Más recientes',
                    SortType.dateAdded,
                    sortType,
                    Icons.access_time,
                  ),
                  _buildSortOption(
                    context,
                    ref,
                    'Más reproducidas',
                    SortType.mostPlayed,
                    sortType,
                    Icons.trending_up,
                  ),
                  _buildSortOption(
                    context,
                    ref,
                    'Duración',
                    SortType.duration,
                    sortType,
                    Icons.timer,
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Sección de Filtros
            _buildSection(
              context,
              'Filtrar por',
              Icons.filter_list,
              Column(
                children: [
                  _buildFilterButton(
                    context,
                    ref,
                    'Género',
                    FilterType.genre,
                    currentFilter[FilterType.genre] ?? [],
                    Icons.audiotrack,
                  ),
                  _buildFilterButton(
                    context,
                    ref,
                    'Artista',
                    FilterType.artist,
                    currentFilter[FilterType.artist] ?? [],
                    Icons.person,
                  ),
                  _buildFilterButton(
                    context,
                    ref,
                    'Álbum',
                    FilterType.album,
                    currentFilter[FilterType.album] ?? [],
                    Icons.album,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Filtros activos
            if (currentFilter.values.any((list) => list.isNotEmpty))
              _buildActiveFilters(context, ref, currentFilter),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Aplicar Filtros'),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    SortType type,
    SortType currentType,
    IconData icon,
  ) {
    final isSelected = type == currentType;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: AppTextStyles.body1(context).copyWith(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(sortTypeProvider.notifier).state = type;
      },
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    FilterType type,
    List<String> currentValues,
    IconData icon,
  ) {
    final hasValues = currentValues.isNotEmpty;

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.body1(context)),
      subtitle: hasValues
          ? Text(
              currentValues.length == 1
                  ? currentValues.first
                  : '${currentValues.length} seleccionados',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.accent,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showFilterOptions(context, ref, type);
      },
    );
  }

  Widget _buildActiveFilters(
    BuildContext context,
    WidgetRef ref,
    Map<FilterType, List<String>> filters,
  ) {
    final allActiveFilters = <MapEntry<FilterType, String>>[];

    filters.forEach((type, values) {
      for (final value in values) {
        allActiveFilters.add(MapEntry(type, value));
      }
    });

    if (allActiveFilters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros activos',
            style: AppTextStyles.heading3(context),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allActiveFilters.map((entry) {
              return Chip(
                label: Text(entry.value),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  final newFilters = Map<FilterType, List<String>>.from(filters);
                  newFilters[entry.key] = List<String>.from(newFilters[entry.key]!)
                    ..remove(entry.value);
                  ref.read(currentFilterProvider.notifier).state = newFilters;
                },
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterOptions(
    BuildContext context,
    WidgetRef ref,
    FilterType type,
  ) async {
    // Obtener las opciones según el tipo de filtro
    List<String> options = [];
    Map<String, String?> albumCovers = {}; // Para almacenar covers de álbumes

    switch (type) {
      case FilterType.genre:
        options = await ref.read(allGenresProvider.future);
        break;
      case FilterType.artist:
        options = await ref.read(allArtistsProvider.future);
        break;
      case FilterType.album:
        options = await ref.read(allAlbumsProvider.future);
        // Obtener covers de álbumes
        final allTracks = await ref.read(allTracksProvider.future);
        for (final album in options) {
          final trackWithCover = allTracks.firstWhere(
            (t) => t.album == album && t.coverArtPath != null,
            orElse: () => allTracks.firstWhere((t) => t.album == album),
          );
          albumCovers[album] = trackWithCover.coverArtPath;
        }
        break;
    }

    if (!context.mounted) return;

    // Estado local para las selecciones
    final currentFilter = ref.read(currentFilterProvider);
    final selectedValues = Set<String>.from(currentFilter[type] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seleccionar ${_getFilterLabel(type)}',
                              style: AppTextStyles.heading3(context),
                            ),
                            if (selectedValues.isNotEmpty)
                              Text(
                                '${selectedValues.length} seleccionados',
                                style: AppTextStyles.caption(context),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (selectedValues.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedValues.clear();
                                  });
                                },
                                child: const Text('Limpiar'),
                              ),
                            TextButton(
                              onPressed: () {
                                // Aplicar selección
                                final newFilters = Map<FilterType, List<String>>.from(
                                  ref.read(currentFilterProvider),
                                );
                                newFilters[type] = selectedValues.toList();
                                ref.read(currentFilterProvider.notifier).state = newFilters;
                                Navigator.pop(context);
                              },
                              child: const Text('Aplicar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Lista de opciones
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = selectedValues.contains(option);
                        final coverPath = type == FilterType.album ? albumCovers[option] : null;

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedValues.add(option);
                              } else {
                                selectedValues.remove(option);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              // Mostrar imagen para álbumes
                              if (type == FilterType.album) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: coverPath != null && File(coverPath).existsSync()
                                        ? Image.file(
                                            File(coverPath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.album,
                                                color: AppColors.primary.withValues(alpha: 0.6),
                                                size: 20,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.album,
                                            color: AppColors.primary.withValues(alpha: 0.6),
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  option,
                                  style: AppTextStyles.body1(context).copyWith(
                                    color: isSelected ? AppColors.primary : null,
                                    fontWeight: isSelected ? FontWeight.w600 : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          activeColor: AppColors.primary,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getFilterLabel(FilterType type) {
    switch (type) {
      case FilterType.genre:
        return 'género';
      case FilterType.artist:
        return 'artista';
      case FilterType.album:
        return 'álbum';
    }
  }
}


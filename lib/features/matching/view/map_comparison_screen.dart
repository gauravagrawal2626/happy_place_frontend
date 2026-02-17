import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import '../../home/widgets/animated_map_widget.dart';
import '../../home/widgets/real_map_widget.dart';
import '../../../services/location_service.dart';
import '../../../services/location_autocomplete_service.dart';

/// MapComparisonScreen allows switching between stylized and real map views.
/// 
/// Features:
/// - Toggle between Real Map and Stylized Map
/// - Current Location (GPS) or Custom Location selection
/// - Search for custom locations
/// - Popular location suggestions
class MapComparisonScreen extends StatefulWidget {
  const MapComparisonScreen({super.key});

  @override
  State<MapComparisonScreen> createState() => _MapComparisonScreenState();
}

class _MapComparisonScreenState extends State<MapComparisonScreen> {
  bool _useRealMap = true;
  bool _useCurrentLocation = true;
  bool _isLoadingLocation = false;
  String? _locationError;
  
  latlong2.LatLng? _currentLocation;
  latlong2.LatLng? _customLocation;
  String _customLocationName = '';
  
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final LocationAutocompleteService _autocompleteService = LocationAutocompleteService();
  
  // Autocomplete state
  Timer? _debounceTimer;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Try to get current location on init
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        final address = await _locationService.getAddressFromLocation(location);
        setState(() {
          _currentLocation = location;
          _customLocationName = address ?? 'Current Location';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _locationError = 'Could not get location. Using default.';
          _currentLocation = PredefinedLocations.hyderabadHitechCity;
          _customLocationName = 'Hitech City, Hyderabad';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Location error. Using default.';
        _currentLocation = PredefinedLocations.hyderabadHitechCity;
        _customLocationName = 'Hitech City, Hyderabad';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final location = await _locationService.getLocationFromAddress(query);
      if (location != null) {
        setState(() {
          _customLocation = location;
          _customLocationName = query;
          _useCurrentLocation = false;
          _isLoadingLocation = false;
        });
        Navigator.pop(context); // Close search sheet
      } else {
        setState(() {
          _locationError = 'Location not found';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Search failed';
        _isLoadingLocation = false;
      });
    }
  }

  void _selectPredefinedLocation(LocationOption option) {
    setState(() {
      _customLocation = option.location;
      _customLocationName = option.name;
      _useCurrentLocation = false;
    });
    Navigator.pop(context);
  }

  latlong2.LatLng get _activeLocation {
    if (_useCurrentLocation && _currentLocation != null) {
      return _currentLocation!;
    }
    return _customLocation ?? PredefinedLocations.hyderabadHitechCity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Find Flats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location selector
              _buildLocationSelector(),
              
              const SizedBox(height: 16),
              
              // Map type toggle
              _buildMapToggle(),
              
              const SizedBox(height: 20),
              
              // Map widget based on selection
              _useRealMap ? _buildRealMap() : _buildStylizedMap(),
              
              const SizedBox(height: 24),
              
              // Info section
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Location type toggle
          Row(
            children: [
              Expanded(
                child: _buildLocationOption(
                  icon: Icons.my_location,
                  label: 'Current',
                  isSelected: _useCurrentLocation,
                  onTap: () {
                    setState(() => _useCurrentLocation = true);
                    if (_currentLocation == null) {
                      _fetchCurrentLocation();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLocationOption(
                  icon: Icons.search,
                  label: 'Custom',
                  isSelected: !_useCurrentLocation,
                  onTap: () => _showLocationSearchSheet(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Current location display
          if (_isLoadingLocation)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Getting location...',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  _useCurrentLocation ? Icons.gps_fixed : Icons.place,
                  size: 16,
                  color: const Color(0xFF667eea),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _customLocationName.isNotEmpty
                        ? _customLocationName
                        : 'Select a location',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_useCurrentLocation)
                  GestureDetector(
                    onTap: () => _showLocationSearchSheet(),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: TextStyle(
                color: Colors.orange.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _selectSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _customLocation = suggestion.location;
      _customLocationName = suggestion.displayName;
      _useCurrentLocation = false;
      _suggestions = [];
    });
    _searchController.clear();
    Navigator.pop(context);
  }

  void _showLocationSearchSheet() {
    _searchController.clear();
    _suggestions = [];
    _isLoadingSuggestions = false;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Search Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Search field with autocomplete
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search area, city, or address...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: _isLoadingSuggestions
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _suggestions = [];
                                    });
                                    setSheetState(() {});
                                  },
                                )
                              : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF667eea)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                    onChanged: (query) {
                      _onSearchChangedWithState(query, setSheetState);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Suggestions list
                  if (_suggestions.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return _buildSuggestionTile(suggestion);
                        },
                      ),
                    )
                  else if (_searchController.text.isEmpty)
                    // Popular locations when search is empty
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Popular Areas',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: PredefinedLocations.popularLocations.length,
                            itemBuilder: (context, index) {
                              final location = PredefinedLocations.popularLocations[index];
                              return _buildPopularLocationTile(location);
                            },
                          ),
                        ),
                      ],
                    )
                  else if (!_isLoadingSuggestions && _searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSearchChangedWithState(String query, StateSetter setSheetState) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      setSheetState(() {});
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });
    setSheetState(() {});

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearchWithState(query, setSheetState);
    });
  }

  Future<void> _performSearchWithState(String query, StateSetter setSheetState) async {
    try {
      final results = await _autocompleteService.search(
        query,
        countryCode: 'in', // Limit to India
        limit: 8,
      );
      
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
        setSheetState(() {});
      }
    } catch (e) {
      print('Error in autocomplete search: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
        setSheetState(() {});
      }
    }
  }

  Widget _buildSuggestionTile(LocationSuggestion suggestion) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.place,
          color: Color(0xFF667eea),
          size: 20,
        ),
      ),
      title: Text(
        suggestion.displayName.split(',').take(2).join(','), // Show first 2 parts
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        suggestion.displayName,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white38,
        size: 16,
      ),
      onTap: () => _selectSuggestion(suggestion),
    );
  }

  Widget _buildPopularLocationTile(LocationOption location) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.place,
          color: Color(0xFF667eea),
          size: 20,
        ),
      ),
      title: Text(
        location.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white38,
        size: 16,
      ),
      onTap: () => _selectPredefinedLocation(location),
    );
  }

  Widget _buildMapToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              'Real Map',
              Icons.map,
              isSelected: _useRealMap,
              onTap: () => setState(() => _useRealMap = true),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              'Stylized',
              Icons.auto_awesome,
              isSelected: !_useRealMap,
              onTap: () => setState(() => _useRealMap = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMap() {
    return RealMapWidget(
      city: _customLocationName.contains(',') 
          ? _customLocationName.split(',').last.trim()
          : 'Hyderabad',
      preference: 'Vegetarian',
      userLocation: _activeLocation,
      radiusKm: 5.0,
      showRadiusCircle: true,
      flats: _getSampleFlatsNearLocation(_activeLocation),
      onModifyPreferences: () => _showPreferencesSheet(context),
      onAddFlatDetails: () => _showAddFlatSheet(context),
    );
  }

  Widget _buildStylizedMap() {
    return AnimatedMapWidget.sample(
      city: _customLocationName.contains(',')
          ? _customLocationName.split(',').last.trim()
          : 'Hyderabad',
      preference: 'Vegetarian',
      onModifyPreferences: () => _showPreferencesSheet(context),
      onAddFlatDetails: () => _showAddFlatSheet(context),
    );
  }

  /// Generate sample flats around the selected location
  List<FlatListing> _getSampleFlatsNearLocation(latlong2.LatLng center) {
    return [
      FlatListing(
        id: '1',
        location: latlong2.LatLng(
          center.latitude + 0.015,
          center.longitude + 0.012,
        ),
        name: '2BHK Modern Flat',
        rent: 18000,
        address: 'Near ${_customLocationName}',
        matchPercentage: 90,
        ownerName: 'Priya',
      ),
      FlatListing(
        id: '2',
        location: latlong2.LatLng(
          center.latitude - 0.020,
          center.longitude - 0.018,
        ),
        name: '3BHK Spacious',
        rent: 25000,
        address: 'Near ${_customLocationName}',
        matchPercentage: 75,
        ownerName: 'Rahul',
      ),
      FlatListing(
        id: '3',
        location: latlong2.LatLng(
          center.latitude + 0.025,
          center.longitude - 0.010,
        ),
        name: '1BHK Cozy',
        rent: 12000,
        address: 'Near ${_customLocationName}',
        matchPercentage: 60,
        ownerName: 'Amit',
      ),
      FlatListing(
        id: '4',
        location: latlong2.LatLng(
          center.latitude - 0.012,
          center.longitude + 0.025,
        ),
        name: '2BHK Premium',
        rent: 30000,
        address: 'Near ${_customLocationName}',
        matchPercentage: 45,
        ownerName: 'Sara',
      ),
      FlatListing(
        id: '5',
        location: latlong2.LatLng(
          center.latitude - 0.030,
          center.longitude + 0.008,
        ),
        name: '3BHK Family',
        rent: 35000,
        address: 'Near ${_customLocationName}',
        matchPercentage: 85,
        ownerName: 'Kiran',
      ),
    ];
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _useRealMap ? Icons.map : Icons.auto_awesome,
                color: Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _useRealMap ? 'OpenStreetMap' : 'Stylized Design',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _useRealMap
                ? 'Shows actual roads, buildings, and landmarks. Flat pins are positioned at their exact geographic coordinates within 5km radius.'
                : 'A decorative map design with stylized road patterns. Pins show relative positions but roads are not real.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showPreferencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modify Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPreferenceRow('Location', _customLocationName.isNotEmpty 
                ? _customLocationName.split(',').first 
                : 'Not set'),
            _buildPreferenceRow('Food', 'Vegetarian'),
            _buildPreferenceRow('Budget', '₹10k - ₹25k'),
            _buildPreferenceRow('Radius', '5 km'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFlatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Your Flat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Flat Name / Society'),
              _buildTextField('Address'),
              _buildTextField('Monthly Rent (₹)'),
              _buildTextField('BHK Type (1/2/3)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Flat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

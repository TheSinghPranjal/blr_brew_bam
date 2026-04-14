import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../domain/models.dart';

class UserInterface extends ConsumerStatefulWidget {
  const UserInterface({super.key});

  @override
  ConsumerState<UserInterface> createState() => _UserInterfaceState();
}

class _UserInterfaceState extends ConsumerState<UserInterface> {
  String _selectedMainTab = '';
  String _selectedSubTab = '';
  int _navIndex = 0;

  static const _mainTabIcons = {
    'Food': Icons.restaurant_menu_rounded,
    'Instamart': Icons.shopping_basket_rounded,
    'Dineout': Icons.dinner_dining_rounded,
    'Giftables': Icons.card_giftcard_rounded,
    'Scenes': Icons.celebration_rounded,
  };

  static const _subTabIcons = {
    'All': Icons.apps_rounded,
    'Fresh': Icons.eco_rounded,
    'Price-Lock': Icons.lock_outline_rounded,
    'Summer': Icons.wb_sunny_outlined,
    'Electronics': Icons.headphones_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<String> mainTabs = List<String>.from(
      user.metadata['accessibleTabs'] ??
          ['Food', 'Instamart', 'Dineout', 'Giftables', 'Scenes'],
    );
    final List<String> subTabs = List<String>.from(
      user.metadata['accessibleSubTabs'] ??
          ['All', 'Fresh', 'Price-Lock', 'Summer', 'Electronics'],
    );

    if (_selectedMainTab.isEmpty ||
        !mainTabs.contains(_selectedMainTab)) {
      _selectedMainTab = mainTabs.isNotEmpty ? mainTabs.first : '';
    }
    if (_selectedSubTab.isEmpty ||
        !subTabs.contains(_selectedSubTab)) {
      _selectedSubTab = subTabs.isNotEmpty ? subTabs.first : '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE2F3F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(user: user, onLogout: _logout),
            const SizedBox(height: 8),
            _MainTabBar(
              tabs: mainTabs,
              selected: _selectedMainTab,
              icons: _mainTabIcons,
              onSelect: (t) => setState(() => _selectedMainTab = t),
            ),
            const SizedBox(height: 8),
            _SearchRow(),
            const SizedBox(height: 4),
            _SubTabBar(
              tabs: subTabs,
              selected: _selectedSubTab,
              icons: _subTabIcons,
              onSelect: (t) => setState(() => _selectedSubTab = t),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _ProductBody(
                mainTab: _selectedMainTab,
                subTab: _selectedSubTab,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_rounded), label: 'Instamart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Categories'),
          BottomNavigationBarItem(
              icon: Icon(Icons.refresh_rounded), label: 'Reorder'),
          BottomNavigationBarItem(
              icon: Icon(Icons.print_rounded), label: 'Print'),
        ],
      ),
    );
  }

  void _logout() {
    ref.read(currentUserProvider.notifier).state = null;
    context.go('/login');
  }
}

// ── Header ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final RestaurantUser user;
  final VoidCallback onLogout;
  const _Header({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7 mins',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F5A57),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'To ${user.name}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF0F5A57),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Color(0xFF0F5A57)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLogout,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.gradientStart,
              backgroundImage: NetworkImage(user.photoUrl),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main Tab Bar ────────────────────────────────────────────────────────
class _MainTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final Map<String, IconData> icons;
  final ValueChanged<String> onSelect;
  const _MainTabBar({
    required this.tabs,
    required this.selected,
    required this.icons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final tab = tabs[i];
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelect(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 78,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white54,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(10),
                ),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[tab] ?? Icons.circle,
                    color: isSelected ? AppColors.primary : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
}

// ── Search Row ─────────────────────────────────────────────────────────
class _SearchRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Search for 'Buttermilk'",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  const Icon(Icons.mic_none_rounded, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Sub-Tab Bar ─────────────────────────────────────────────────────────
class _SubTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final Map<String, IconData> icons;
  final ValueChanged<String> onSelect;
  const _SubTabBar({
    required this.tabs,
    required this.selected,
    required this.icons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final tab = tabs[i];
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelect(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                border: isSelected
                    ? Border(
                        top: BorderSide(
                            color: AppColors.primary, width: 2),
                        left: BorderSide(
                            color: AppColors.primary, width: 2),
                        right: BorderSide(
                            color: AppColors.primary, width: 2),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icons[tab] ?? Icons.label_outline,
                    size: 15,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
}

// ── Product Body ────────────────────────────────────────────────────────
class _ProductBody extends StatelessWidget {
  final String mainTab;
  final String subTab;
  const _ProductBody({required this.mainTab, required this.subTab});

  static const _products = [
    {
      'name': 'Kimia Dates (Kharjura)',
      'weight': '400 g',
      'price': '229',
      'oldPrice': '297',
      'image': 'https://images.unsplash.com/photo-1596482161271-2ed2dc858739?w=400&q=70',
    },
    {
      'name': 'Garlic Peeled – Urban Harvest',
      'weight': '100 g',
      'price': '49',
      'oldPrice': '73',
      'image': 'https://images.unsplash.com/photo-1540148426945-816742512f43?w=400&q=70',
    },
    {
      'name': 'Fenugreek Without Roots',
      'weight': '1 Bunch',
      'price': '29',
      'oldPrice': '36',
      'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=70',
    },
    {
      'name': 'Green Kiwi',
      'weight': '3 Pieces',
      'price': '150',
      'oldPrice': '194',
      'image': 'https://images.unsplash.com/photo-1585062544865-c4224734da65?w=400&q=70',
    },
    {
      'name': 'Masala Dosa',
      'weight': '1 Plate',
      'price': '120',
      'oldPrice': '140',
      'image': 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?w=400&q=70',
    },
    {
      'name': 'Kingfisher Premium',
      'weight': '330 ml',
      'price': '150',
      'oldPrice': '180',
      'image': 'https://images.unsplash.com/photo-1608270586620-248524c67de9?w=400&q=70',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFD3EBE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Lowest Prices\nEveryday',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F5A57),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16)),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=300&q=70',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              '$mainTab › $subTab',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: _products.length,
              itemBuilder: (ctx, i) => _ProductCard(
                data: _products[i],
              ),
            ),
          ),

          // Promo banner
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3DDF9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Brand of the Day!',
                            style: TextStyle(fontSize: 11)),
                        SizedBox(height: 4),
                        Text(
                          'Fuel your day the mindful way with Yogabar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, String> data;
  const _ProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  data['image']!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.gradientStart,
                    child: const Icon(Icons.fastfood_rounded,
                        color: AppColors.primary, size: 40),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name']!,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    data['weight']!,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${data['price']}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₹${data['oldPrice']}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

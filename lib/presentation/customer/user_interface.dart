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

// ── Mock Product Model (mirrors DynamoDB schema) ───────────────────────
class MockProduct {
  final String productId;
  final String name;          // product_name
  final String weight;
  final String productIngredients;
  final double price;
  final double oldPrice;
  final bool available;
  final int calories;
  final String prepTime;
  final String category;
  final String subcategory;
  final String chef;
  final String ingredients;
  final String image;

  const MockProduct({
    required this.productId,
    required this.name,
    required this.weight,
    this.productIngredients = '',
    required this.price,
    required this.oldPrice,
    this.available = true,
    required this.calories,
    this.prepTime = '',
    this.category = '',
    this.subcategory = '',
    this.chef = '',
    this.ingredients = '',
    this.image = '',
  });
}

// ── Product Body ────────────────────────────────────────────────────────
class _ProductBody extends StatelessWidget {
  final String mainTab;
  final String subTab;
  const _ProductBody({required this.mainTab, required this.subTab});

  static const _products = [
    MockProduct(
      productId: 'PRD001',
      name: 'Kimia Dates (Kharjura)',
      weight: '400 g',
      productIngredients: 'Dried Dates',
      price: 229,
      oldPrice: 297,
      available: true,
      calories: 277,
      prepTime: 'Ready to eat',
      category: 'Dry Fruits',
      subcategory: 'Dates',
      chef: 'Priya Nair',
      ingredients: 'Kimia Dates (100%)',
      image: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=70',
    ),
    MockProduct(
      productId: 'PRD002',
      name: 'Garlic Peeled – Urban Harvest',
      weight: '100 g',
      productIngredients: 'Fresh Garlic',
      price: 49,
      oldPrice: 73,
      available: true,
      calories: 149,
      prepTime: 'Ready to use',
      category: 'Vegetables',
      subcategory: 'Alliums',
      chef: 'Marco Rossi',
      ingredients: 'Peeled Garlic (100%)',
      image: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=70',
    ),
    MockProduct(
      productId: 'PRD003',
      name: 'Fenugreek Without Roots',
      weight: '1 Bunch',
      productIngredients: 'Fresh Methi Leaves',
      price: 29,
      oldPrice: 36,
      available: true,
      calories: 49,
      prepTime: 'Ready to cook',
      category: 'Vegetables',
      subcategory: 'Leafy Greens',
      chef: 'Priya Nair',
      ingredients: 'Fenugreek Leaves (100%)',
      image: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=70',
    ),
    MockProduct(
      productId: 'PRD004',
      name: 'Green Kiwi',
      weight: '3 Pieces',
      productIngredients: 'Fresh Kiwi',
      price: 150,
      oldPrice: 194,
      available: true,
      calories: 61,
      prepTime: 'Ready to eat',
      category: 'Fruits',
      subcategory: 'Exotic Fruits',
      chef: 'Marco Rossi',
      ingredients: 'Green Kiwi (100%)',
      image: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&q=70',
    ),
    MockProduct(
      productId: 'PRD005',
      name: 'Masala Dosa',
      weight: '1 Plate',
      productIngredients: 'Rice, Urad Dal, Potato, Spices',
      price: 120,
      oldPrice: 140,
      available: true,
      calories: 350,
      prepTime: '15 mins',
      category: 'Food',
      subcategory: 'South Indian',
      chef: 'Priya Nair',
      ingredients: 'Rice Batter, Potato Filling, Ghee, Mustard, Curry Leaves',
      image: 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?w=400&q=70',
    ),
    MockProduct(
      productId: 'PRD006',
      name: 'Kingfisher Premium',
      weight: '330 ml',
      productIngredients: 'Water, Malted Barley, Hops',
      price: 150,
      oldPrice: 180,
      available: false,
      calories: 153,
      prepTime: 'Chilled & served',
      category: 'Beverage',
      subcategory: 'Beer',
      chef: 'Nina D\'Souza',
      ingredients: 'Water, Barley Malt, Hops, Yeast',
      image: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?w=400&q=70',
    ),
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
  final MockProduct data;
  const _ProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
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
            // ── Image + badges ──────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: ColorFiltered(
                    colorFilter: data.available
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation),
                    child: Image.network(
                      data.image,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 110,
                        color: AppColors.gradientStart,
                        child: const Icon(Icons.fastfood_rounded,
                            color: AppColors.primary, size: 40),
                      ),
                    ),
                  ),
                ),
                // Unavailable overlay
                if (!data.available)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Unavailable',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // Add button (disabled when unavailable)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: data.available
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),

            // ── Info ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      data.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Weight pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        data.weight,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Calories + Prep Time
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 10, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          '${data.calories} kcal',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        ),
                        if (data.prepTime.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.schedule_rounded,
                              size: 10, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              data.prepTime,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),

                    // Price row
                    Row(
                      children: [
                        Text(
                          '₹${data.price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${data.oldPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product Detail Bottom Sheet ────────────────────────────────────────
  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: data),
    );
  }
}

// ── Product Detail Sheet ──────────────────────────────────────────────
class _ProductDetailSheet extends StatelessWidget {
  final MockProduct product;
  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    product.image,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: AppColors.gradientStart,
                      child: const Icon(Icons.fastfood_rounded,
                          color: AppColors.primary, size: 60),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + availability
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.available
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.available ? 'Available' : 'Unavailable',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: product.available
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ID + category breadcrumb
                      Text(
                        'ID: ${product.productId}  •  ${product.category}'
                        '${product.subcategory.isNotEmpty ? " › ${product.subcategory}" : ""}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price row
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${product.oldPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(((product.oldPrice - product.price) / product.oldPrice) * 100).round()}% off',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.local_fire_department_rounded,
                            label: '${product.calories} kcal',
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.schedule_rounded,
                            label: product.prepTime.isEmpty
                                ? 'N/A'
                                : product.prepTime,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.scale_rounded,
                            label: product.weight,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Chef
                      if (product.chef.isNotEmpty)
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Chef',
                          value: product.chef,
                        ),

                      // Ingredients
                      if (product.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.restaurant_rounded,
                          label: 'Ingredients',
                          value: product.ingredients,
                        ),
                      ],

                      // Product Ingredients (raw)
                      if (product.productIngredients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.grass_rounded,
                          label: 'Raw Ingredients',
                          value: product.productIngredients,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Add to cart
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              product.available ? () {} : null,
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(product.available
                              ? 'Add to Cart'
                              : 'Currently Unavailable'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

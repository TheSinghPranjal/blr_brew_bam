import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/field_agent_providers.dart';
import '../../domain/restaurant_model.dart';

class AddRestaurantScreen extends ConsumerStatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  ConsumerState<AddRestaurantScreen> createState() =>
      _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends ConsumerState<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  RestaurantType _selectedType = RestaurantType.cafe;

  // Dynamic email list (1 field by default)
  final List<TextEditingController> _emailCtrls = [TextEditingController()];
  final List<FocusNode> _emailFocusNodes = [FocusNode()];

  bool _hasSubmitted = false;
  String? _emailListError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    for (final c in _emailCtrls) {
      c.dispose();
    }
    for (final f in _emailFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────
  bool _validateEmails() {
    if (_emailCtrls.length > 3) {
      setState(() => _emailListError = 'Maximum 3 super admin emails allowed');
      return false;
    }
    final emails = _emailCtrls
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (emails.isEmpty) {
      setState(() =>
          _emailListError = 'At least one super admin email is required');
      return false;
    }

    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    for (final email in emails) {
      if (!emailRegex.hasMatch(email)) {
        setState(() => _emailListError = '"$email" is not a valid email');
        return false;
      }
    }

    setState(() => _emailListError = null);
    return true;
  }

  // ── Submit ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _hasSubmitted = true);
    final formValid = _formKey.currentState!.validate();
    final emailsValid = _validateEmails();

    if (!formValid || !emailsValid) return;

    final emails = _emailCtrls
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await ref.read(fieldAgentProvider.notifier).addRestaurant(
          name: _nameCtrl.text,
          type: _selectedType,
          city: _cityCtrl.text,
          area: _areaCtrl.text,
          address: _addressCtrl.text,
          superAdminEmails: emails,
        );

    if (!mounted) return;

    final status = ref.read(fieldAgentProvider).status;
    if (status == AddRestaurantStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Restaurant "${_nameCtrl.text.trim()}" added successfully!',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
      ref.read(fieldAgentProvider.notifier).resetStatus();
    }
  }

  // ── Email list helpers ─────────────────────────────────────────────────
  void _addEmailField() {
    if (_emailCtrls.length >= 3) {
      setState(() =>
          _emailListError = 'You can add a maximum of 3 super admin emails');
      return;
    }
    setState(() {
      _emailCtrls.add(TextEditingController());
      _emailFocusNodes.add(FocusNode());
      _emailListError = null;
    });
  }

  void _removeEmailField(int index) {
    setState(() {
      _emailCtrls[index].dispose();
      _emailCtrls.removeAt(index);
      _emailFocusNodes[index].dispose();
      _emailFocusNodes.removeAt(index);
      _emailListError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(fieldAgentProvider);
    final isLoading = agentState.status == AddRestaurantStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Add Restaurant',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: AppColors.border,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ── Progress Indicator ─────────────────────────────────────
            if (isLoading) ...[
              LinearProgressIndicator(
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],

            // ── Section: Basic Info ────────────────────────────────────
            _SectionHeader(
              icon: Icons.storefront_outlined,
              title: 'Basic Information',
              subtitle: 'Name and type of the restaurant',
            ),
            const SizedBox(height: 12),

            // Restaurant Name
            _FieldLabel(label: 'Restaurant Name', required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. The Brew House',
                prefixIcon: Icon(Icons.store_mall_directory_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Restaurant name is required';
                }
                if (v.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Type
            _FieldLabel(label: 'Restaurant Type', required: true),
            const SizedBox(height: 6),
            _TypeSelector(
              selected: _selectedType,
              onChanged: isLoading
                  ? null
                  : (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 24),

            // ── Section: Location ─────────────────────────────────────
            _SectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: 'Where is this restaurant located?',
            ),
            const SizedBox(height: 12),

            // City
            _FieldLabel(label: 'City', required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cityCtrl,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Bengaluru',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'City is required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Area / Locality
            _FieldLabel(label: 'Area / Locality', required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _areaCtrl,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Koramangala',
                prefixIcon: Icon(Icons.near_me_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Area / Locality is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Full Address
            _FieldLabel(label: 'Full Address', required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressCtrl,
              enabled: !isLoading,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'e.g. 123, 5th Cross, 6th Block, Koramangala, Bengaluru – 560095',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.home_outlined),
                ),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Full address is required';
                }
                if (v.trim().length < 10) {
                  return 'Please enter a more complete address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Section: Super Admin Emails ───────────────────────────
            _SectionHeader(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Super Admin Emails',
              subtitle: 'Assign 1–3 admins who will manage this restaurant',
            ),
            const SizedBox(height: 12),

            // Dynamic email fields
            ...List.generate(_emailCtrls.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrls[i],
                        focusNode: _emailFocusNodes[i],
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'admin${i + 1}@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          suffixText: i == 0 ? 'Required' : 'Optional',
                          suffixStyle: GoogleFonts.outfit(
                            fontSize: 11,
                            color: i == 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        onChanged: (_) {
                          if (_hasSubmitted) _validateEmails();
                        },
                      ),
                    ),
                    // Remove button (not for first field)
                    if (i > 0) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: isLoading ? null : () => _removeEmailField(i),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 40,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Email error
            if (_emailListError != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(
                    _emailListError!,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.error),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // Add Email button
            if (_emailCtrls.length < 3)
              OutlinedButton.icon(
                onPressed: isLoading ? null : _addEmailField,
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Another Email (${3 - _emailCtrls.length} remaining)',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            const SizedBox(height: 32),

            // ── Submit Button ─────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Submit & Onboard Restaurant',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
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
}

// ── Type Selector ──────────────────────────────────────────────────────────
class _TypeSelector extends StatelessWidget {
  final RestaurantType selected;
  final ValueChanged<RestaurantType>? onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RestaurantType>(
      value: selected,
      onChanged: onChanged == null ? null : (v) => onChanged!(v!),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category_outlined),
      ),
      borderRadius: BorderRadius.circular(12),
      items: RestaurantType.values
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    t.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.gradientStart,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Field Label ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ],
    );
  }
}

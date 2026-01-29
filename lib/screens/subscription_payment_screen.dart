import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  String _country = 'Ecuador';
  bool _acceptTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _payWithCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago con tarjeta simulado — Suscripción activada')),
      );
      Navigator.of(context).pop();
    }
  }

  void _payWithPaypal() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago con PayPal simulado — Suscripción activada')),
      );
      Navigator.of(context).pop();
    }
  }

  void _subscribe() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes aceptar los términos')));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suscripción activada — Pago simulado')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Pago de suscripción', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // header card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/logo1.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('ConVive Premium+', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('Accede a beneficios exclusivos', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Text('\$7.99', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // form card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Ingresa los datos de tu tarjeta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cardNumberCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.credit_card_outlined),
                            hintText: '0000 0000 0000 0000',
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                                  child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/visa.png',
                                    width: 28,
                                    height: 18,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.credit_card, size: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 6),
                                  Image.asset(
                                    'assets/images/discover.png',
                                    width: 28,
                                    height: 18,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.payment, size: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(minWidth: 72),
                          ),
                          validator: (v) => (v == null || v.replaceAll(' ', '').length < 12) ? 'Número inválido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline),
                            hintText: 'Nombre en la tarjeta',
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Nombre requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            hintText: 'Línea 1 de dirección',
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _country,
                          items: const [
                            DropdownMenuItem(value: 'Ecuador', child: Text('Ecuador')),
                            DropdownMenuItem(value: 'España', child: Text('España')),
                            DropdownMenuItem(value: 'México', child: Text('México')),
                          ],
                          onChanged: (v) { if (v!=null) setState(()=> _country = v); },
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: AppColors.inputFill),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryCtrl,
                                decoration: InputDecoration(
                                  hintText: 'MM/AA',
                                  filled: true,
                                  fillColor: AppColors.inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                validator: (v) => (v == null || v.length < 4) ? 'Inválido' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TextFormField(
                                controller: _cvvCtrl,
                                decoration: InputDecoration(
                                  hintText: 'CVV',
                                  filled: true,
                                  fillColor: AppColors.inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => (v == null || v.length < 3) ? 'Inv' : null,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _payWithCard,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _loading ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text('Pagar con tarjeta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _payWithPaypal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003087), // PayPal blue
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/images/paypal.jpg',
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (ctx, err, stack) => const FaIcon(FontAwesomeIcons.paypal, size: 20, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(child: Text('O paga con', style: TextStyle(color: AppColors.textSecondary))),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              // RUC / Company field (optional)
              TextFormField(
                controller: _rucCtrl,
                decoration: InputDecoration(
                  hintText: 'RUC (opcional)',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: _acceptTerms, onChanged: (v) => setState(()=> _acceptTerms = v ?? false)),
                  Expanded(child: Text('Acepta que ConVive cobrará en tu tarjeta el importe indicado ahora y de forma recurrente mensual hasta que canceles.', style: TextStyle(color: AppColors.textSecondary))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _loading ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text('Suscribirse', style: TextStyle(fontSize:16,fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

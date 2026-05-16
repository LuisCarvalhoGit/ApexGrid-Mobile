import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/garage_controller.dart';
import '../models/motorcycle.dart';

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});
  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    final fleet = ref.watch(garageProvider);

    // Mota que está atualmente visível no carrossel para mostrar o Pit Stop dela
    // Num MVP mais simples, podemos focar apenas na default
    final visibleBike = fleet.isNotEmpty 
        ? fleet.firstWhere((b) => b.isDefault, orElse: () => fleet.first) 
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GARAGEM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
      ),
      body: fleet.isEmpty 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : SingleChildScrollView(
            child: Column(
              children: [
                // 1. CARROSSEL DE MOTAS
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: fleet.length + 1,
                    itemBuilder: (context, index) {
                      if (index == fleet.length) return _buildAddCard();
                      return _buildBikeCard(fleet[index]);
                    },
                  ),
                ),

                const SizedBox(height: 30),
                
                // 2. PIT STOP (Ligado à mota principal)
                if (visibleBike != null) _buildMaintenanceSection(visibleBike),
              ],
            ),
          ),
    );
  }

  Widget _buildBikeCard(Motorcycle bike) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bike.isDefault ? Colors.amberAccent : Colors.white10, width: bike.isDefault ? 2 : 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bike.model, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${bike.brand} • ${bike.engineCc}cc', style: const TextStyle(color: Colors.white54)),
                const Spacer(),
                
                // Métrica de Odómetro e Botão Principal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${bike.currentOdometer} KM', style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    
                    // BOTÃO "DEFINIR COMO PRINCIPAL"
                    if (bike.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amberAccent)),
                        child: const Text('ATIVA', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      )
                    else
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () => ref.read(garageProvider.notifier).setAsDefault(bike.id),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 8)),
                          child: const Text('USAR ESTA', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white24, size: 20),
              onPressed: () => _showEditBikeModal(bike),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () => _showAddBikeModal(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, style: BorderStyle.none),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 40),
              SizedBox(height: 10),
              Text('ADICIONAR MOTA', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // --- SECÇÃO DO PIT STOP ---
  Widget _buildMaintenanceSection(Motorcycle bike) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PIT STOP & MANUTENÇÃO', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
              Text(bike.model.toUpperCase(), style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMaintenanceTracker(
            bike: bike,
            type: 'chain',
            title: 'LUBRIFICAÇÃO CORRENTE',
            icon: Icons.link,
            intervalKm: 500,
            history: bike.chainHistory,
          ),
          const SizedBox(height: 12),
          _buildMaintenanceTracker(
            bike: bike,
            type: 'oil',
            title: 'MUDANÇA DE ÓLEO',
            icon: Icons.water_drop_outlined,
            intervalKm: 10000,
            history: bike.oilHistory,
          ),
          const SizedBox(height: 12),
          _buildMaintenanceTracker(
            bike: bike,
            type: 'tires',
            title: 'ESTADO DOS PNEUS',
            icon: Icons.trip_origin,
            intervalKm: 12000,
            history: bike.tiresHistory,
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTracker({
    required Motorcycle bike,
    required String type,
    required String title,
    required IconData icon,
    required int intervalKm,
    required List<MaintenanceEvent> history,
  }) {
    final bool hasHistory = history.isNotEmpty;
    
    // Cálculos (só importam se houver histórico)
    final int lastServiceKm = hasHistory ? history.last.odometerAtEvent : 0;
    final int kmsSinceService = bike.currentOdometer - lastServiceKm;
    final int remainingKms = intervalKm - kmsSinceService;
    final double percentage = (kmsSinceService / intervalKm).clamp(0.0, 1.0);
    
    final bool isWarning = remainingKms <= 0;
    final Color barColor = isWarning ? Colors.redAccent : Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: hasHistory ? Colors.white54 : Colors.white24, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: hasHistory ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
              
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () => _showMaintenanceHistory(bike, type),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(color: hasHistory ? Colors.white24 : Colors.cyanAccent.withValues(alpha:0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(hasHistory ? 'HISTÓRICO' : 'REGISTAR', style: TextStyle(color: hasHistory ? Colors.white70 : Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // ESTADO VAZIO (NENHUM REGISTO) VS COM REGISTO
          if (!hasHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('A aguardar o primeiro registo...', style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isWarning ? 'MUDANÇA EXIGIDA' : 'Faltam $remainingKms km', style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('${(percentage * 100).toInt()}% Desgaste', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white.withValues(alpha:0.05),
                color: barColor,
                minHeight: 6,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // --- MODAIS DA APLICAÇÃO ---

  void _showMaintenanceHistory(Motorcycle bike, String type) {
    final history = type == 'oil' ? bike.oilHistory : type == 'chain' ? bike.chainHistory : bike.tiresHistory;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('HISTÓRICO: ${type.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          if (history.isEmpty)
            const Expanded(child: Center(child: Text('Nenhum registo efetuado.', style: TextStyle(color: Colors.white24))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (ctx, i) {
                  final event = history[history.length - 1 - i]; // Mostra o mais recente primeiro
                  return ListTile(
                    title: Text('${event.odometerAtEvent} KM', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${event.date.day}/${event.date.month}/${event.date.year}', style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.cyanAccent),
                      onPressed: () => _showEditEventModal(bike, type, event),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.pop(ctx);
                _addNewEvent(bike, type);
              },
              child: const Text('ADICIONAR REGISTO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showAddBikeModal() {
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final ccCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADICIONAR NOVA MOTA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildField(brandCtrl, 'Marca', 'Ex: Yamaha'),
            _buildField(modelCtrl, 'Modelo', 'Ex: MT-07'),
            Row(
              children: [
                Expanded(child: _buildField(yearCtrl, 'Ano', '2023', isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(ccCtrl, 'Cilindrada', '689', isNumber: true)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final newBike = Motorcycle(
                    id: DateTime.now().toString(),
                    brand: brandCtrl.text,
                    model: modelCtrl.text,
                    year: int.tryParse(yearCtrl.text) ?? 2024,
                    engineCc: int.tryParse(ccCtrl.text) ?? 0,
                    weightKg: 200,
                    currentOdometer: 0,
                  );
                  ref.read(garageProvider.notifier).addMotorcycle(newBike);
                  Navigator.pop(ctx);
                },
                child: const Text('ADICIONAR À GARAGEM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white10),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
        ),
      ),
    );
  }

  void _showEditBikeModal(Motorcycle bike) {
    final kmCtrl = TextEditingController(text: bike.currentOdometer.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EDITAR ${bike.model.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: kmCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'Odómetro Atual (KM)',
                labelStyle: TextStyle(color: Colors.cyanAccent),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final newKm = int.tryParse(kmCtrl.text) ?? bike.currentOdometer;
                  ref.read(garageProvider.notifier).updateMotorcycle(bike.copyWith(currentOdometer: newKm));
                  Navigator.pop(ctx);
                },
                child: const Text('GUARDAR ALTERAÇÕES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _addNewEvent(Motorcycle bike, String type) {
    final kmCtrl = TextEditingController(text: bike.currentOdometer.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('NOVO REGISTO', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: kmCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Quilometragem (KM)', labelStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () {
              final newEvent = MaintenanceEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                date: DateTime.now(),
                odometerAtEvent: int.tryParse(kmCtrl.text) ?? bike.currentOdometer,
              );
              ref.read(garageProvider.notifier).addMaintenance(bike.id, type, newEvent);
              Navigator.pop(ctx);
            },
            child: const Text('REGISTAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditEventModal(Motorcycle bike, String type, MaintenanceEvent event) {
    final kmCtrl = TextEditingController(text: event.odometerAtEvent.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('EDITAR REGISTO', style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: kmCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Quilometragem (KM)', labelStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
            onPressed: () {
              final updatedEvent = MaintenanceEvent(
                id: event.id,
                date: event.date,
                odometerAtEvent: int.tryParse(kmCtrl.text) ?? event.odometerAtEvent,
                notes: event.notes,
              );
              ref.read(garageProvider.notifier).editMaintenance(bike.id, type, event.id, updatedEvent);
              Navigator.pop(ctx);
            },
            child: const Text('ATUALIZAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
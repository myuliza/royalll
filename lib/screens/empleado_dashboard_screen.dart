import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';

class EmpleadoDashboardScreen extends StatelessWidget {
  const EmpleadoDashboardScreen({super.key});

  Future<void> _editarStock(BuildContext context, Producto p) async {
    final ctrl = TextEditingController(text: p.stock.toString());
    final nuevoStock = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.nombre),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = int.tryParse(ctrl.text.trim());
              Navigator.pop(context, valor);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoStock != null) {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(p.id)
          .update({'stock': nuevoStock});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock de "${p.nombre}" actualizado a $nuevoStock')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        title: const Text('Panel empleado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar productos'));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.dorado));
          }
          final productos = snapshot.data!.docs
              .map((d) =>
                  Producto.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos cargados'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = productos[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Stock actual: ${p.stock}',
                              style: const TextStyle(
                                  color: AppColors.textoSecundario, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.dorado),
                      onPressed: () => _editarStock(context, p),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
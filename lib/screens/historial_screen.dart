import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;
  int _mesesTendencia = 3;

  final List<String> _nombresMeses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final provider = context.read<AppProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('Historial')),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: provider.firestoreService.getMovimientos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final todos = snapshot.data?.docs ?? [];

              // Filtrar por mes y año seleccionado
              final movimientosMes = todos.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fecha = data['fecha'] != null
                    ? (data['fecha'] as Timestamp).toDate()
                    : null;
                if (fecha == null) return false;
                return fecha.month == _mesSeleccionado &&
                    fecha.year == _anioSeleccionado;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector mes/año
                    _SelectorFecha(
                      mes: _mesSeleccionado,
                      anio: _anioSeleccionado,
                      nombresMeses: _nombresMeses,
                      onCambio: (mes, anio) =>
                          setState(() {
                            _mesSeleccionado = mes;
                            _anioSeleccionado = anio;
                          }),
                    ),

                    const SizedBox(height: 20),

                    // Resumen rápido
                    _ResumenRapido(
                      movimientos: movimientosMes,
                      currency: provider.currency,
                    ),

                    const SizedBox(height: 20),

                    // Donut de gastos
                    _SeccionDonut(
                      movimientos: movimientosMes,
                      currency: provider.currency,
                    ),

                    const SizedBox(height: 20),

                    // Tendencia barras
                    _SeccionTendencia(
                      todos: todos,
                      meses: _mesesTendencia,
                      nombresMeses: _nombresMeses,
                      currency: provider.currency,
                      onCambioMeses: (val) =>
                          setState(() => _mesesTendencia = val),
                    ),

                    const SizedBox(height: 20),

                    // Top sobres
                    _SeccionTopSobres(
                      movimientos: movimientosMes,
                      currency: provider.currency,
                    ),

                    const SizedBox(height: 20),

                    // Progreso ahorros
                    _SeccionAhorros(provider: provider),

                    const SizedBox(height: 20),

                                       // Movimientos recientes (Solo los últimos 10)
                    _SeccionMovimientos(
                      movimientos: movimientosMes.take(10).toList(), // <-- El cambio está aquí
                      currency: provider.currency,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Selector de fecha ───────────────────────────────────────────────────────

class _SelectorFecha extends StatelessWidget {
  final int mes;
  final int anio;
  final List<String> nombresMeses;
  final Function(int, int) onCambio;

  const _SelectorFecha({
    required this.mes,
    required this.anio,
    required this.nombresMeses,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final anioActual = DateTime.now().year;
    final anios = List.generate(5, (i) => anioActual - i);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _DropdownFiltro(
            valor: mes,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(nombresMeses[i],
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            onChanged: (val) => onCambio(val!, anio),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _DropdownFiltro(
            valor: anio,
            items: anios
                .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text('$a',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ))
                .toList(),
            onChanged: (val) => onCambio(mes, val!),
          ),
        ),
      ],
    );
  }
}

class _DropdownFiltro extends StatelessWidget {
  final int valor;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?> onChanged;

  const _DropdownFiltro({
    required this.valor,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: valor,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Resumen rápido ──────────────────────────────────────────────────────────

class _ResumenRapido extends StatelessWidget {
  final List<QueryDocumentSnapshot> movimientos;
  final String currency;

  const _ResumenRapido({required this.movimientos, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    double totalIngresos = 0;
    double totalGastos = 0;

    for (final doc in movimientos) {
      final data = doc.data() as Map<String, dynamic>;
      final tipo = data['tipo'] as String;
      final monto = (data['monto'] as num).toDouble().abs();
      if (tipo == 'ingreso') totalIngresos += monto;
      if (tipo == 'gasto') totalGastos += monto;
    }

    final saldo = totalIngresos - totalGastos;

    return Row(
      children: [
        Expanded(
          child: _ChipResumen(
            label: 'Ingresos',
            monto: totalIngresos,
            color: Colors.green,
            currency: currency,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChipResumen(
            label: 'Gastos',
            monto: totalGastos,
            color: Colors.red,
            currency: currency,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChipResumen(
            label: 'Saldo',
            monto: saldo,
            color: saldo >= 0 ? honey : Colors.red,
            currency: currency,
          ),
        ),
      ],
    );
  }
}

class _ChipResumen extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;
  final String currency;

  const _ChipResumen({
    required this.label,
    required this.monto,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(monto.abs(), currency),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Donut de gastos ─────────────────────────────────────────────────────────

class _SeccionDonut extends StatefulWidget {
  final List<QueryDocumentSnapshot> movimientos;
  final String currency;

  const _SeccionDonut({required this.movimientos, required this.currency});

  @override
  State<_SeccionDonut> createState() => _SeccionDonutState();
}

class _SeccionDonutState extends State<_SeccionDonut> {
  int _touched = -1;

  static const List<Color> _colores = [
    Color(0xFFF59E0B),
    Color(0xFF0F3A30),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    // Calcular gastos por categoría
    final Map<String, double> gastosPorCategoria = {};
    for (final doc in widget.movimientos) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['tipo'] != 'gasto') continue;
      final nombre = data['categoriaOrigenNombre'] as String? ?? 'Otros';
      final monto = (data['monto'] as num).toDouble().abs();
      gastosPorCategoria[nombre] = (gastosPorCategoria[nombre] ?? 0) + monto;
    }

    if (gastosPorCategoria.isEmpty) {
      return _TarjetaVacia(mensaje: 'Sin gastos registrados este mes.');
    }

    final total =
        gastosPorCategoria.values.fold(0.0, (a, b) => a + b);

    // Agrupar menores al 15% en "Otros"
    final Map<String, double> agrupado = {};
    double otros = 0;
    final sorted = gastosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      final porcentaje = entry.value / total;
      if (porcentaje < 0.15 && sorted.length > 3) {
        otros += entry.value;
      } else {
        agrupado[entry.key] = entry.value;
      }
    }
    if (otros > 0) agrupado['Otros'] = otros;

    final entries = agrupado.entries.toList();

    return _TarjetaSeccion(
      titulo: '¿En qué gasté más?',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touched = -1;
                        return;
                      }
                      _touched =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touched;
                  final porcentaje = entries[i].value / total * 100;
                  return PieChartSectionData(
                    value: entries[i].value,
                    color: _colores[i % _colores.length],
                    radius: isTouched ? 36 : 28,
                    title: isTouched ? '${porcentaje.toStringAsFixed(1)}%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Leyenda
          ...List.generate(entries.length, (i) {
            final porcentaje = entries[i].value / total * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colores[i % _colores.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entries[i].key,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(entries[i].value, widget.currency),
                    style: TextStyle(
                        color: _colores[i % _colores.length],
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Tendencia barras ─────────────────────────────────────────────────────────

class _SeccionTendencia extends StatelessWidget {
  final List<QueryDocumentSnapshot> todos;
  final int meses;
  final List<String> nombresMeses;
  final String currency;
  final ValueChanged<int> onCambioMeses;

  const _SeccionTendencia({
    required this.todos,
    required this.meses,
    required this.nombresMeses,
    required this.currency,
    required this.onCambioMeses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final now = DateTime.now();

    // Calcular datos por mes
    final List<Map<String, dynamic>> datosMeses = [];
    for (int i = meses - 1; i >= 0; i--) {
      final fecha = DateTime(now.year, now.month - i, 1);
      double ingresos = 0;
      double gastos = 0;

      for (final doc in todos) {
        final data = doc.data() as Map<String, dynamic>;
        final docFecha = data['fecha'] != null
            ? (data['fecha'] as Timestamp).toDate()
            : null;
        if (docFecha == null) continue;
        if (docFecha.month != fecha.month || docFecha.year != fecha.year) {
          continue;
        }
        final tipo = data['tipo'] as String;
        final monto = (data['monto'] as num).toDouble().abs();
        if (tipo == 'ingreso') ingresos += monto;
        if (tipo == 'gasto') gastos += monto;
      }

      datosMeses.add({
        'label': nombresMeses[fecha.month - 1].substring(0, 3),
        'ingresos': ingresos,
        'gastos': gastos,
      });
    }

    final maxY = datosMeses
        .map((d) => [d['ingresos'] as double, d['gastos'] as double])
        .expand((e) => e)
        .fold(0.0, (a, b) => a > b ? a : b);

    return _TarjetaSeccion(
      titulo: 'Ingresos vs Gastos',
      accion: Row(
        mainAxisSize: MainAxisSize.min,
        children: [3, 6, 12].map((m) {
          final selected = m == meses;
          return GestureDetector(
            onTap: () => onCambioMeses(m),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? honey
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${m}m',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2 == 0 ? 100 : maxY * 1.2,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= datosMeses.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        datosMeses[idx]['label'] as String,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(datosMeses.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: datosMeses[i]['ingresos'] as double,
                    color: Colors.green.withOpacity(0.7),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: datosMeses[i]['gastos'] as double,
                    color: Colors.red.withOpacity(0.7),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Top sobres ──────────────────────────────────────────────────────────────

class _SeccionTopSobres extends StatelessWidget {
  final List<QueryDocumentSnapshot> movimientos;
  final String currency;

  const _SeccionTopSobres(
      {required this.movimientos, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    final Map<String, double> gastosPorSobre = {};
    for (final doc in movimientos) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['tipo'] != 'gasto') continue;
      final nombre = data['categoriaOrigenNombre'] as String? ?? 'Sin nombre';
      final monto = (data['monto'] as num).toDouble().abs();
      gastosPorSobre[nombre] = (gastosPorSobre[nombre] ?? 0) + monto;
    }

    if (gastosPorSobre.isEmpty) {
      return _TarjetaVacia(mensaje: 'Sin gastos registrados este mes.');
    }

    final sorted = gastosPorSobre.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final maxMonto = top.first.value;

    return _TarjetaSeccion(
      titulo: 'Sobres más activos',
      child: Column(
        children: List.generate(top.length, (i) {
          final progreso = top[i].value / maxMonto;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${i + 1}.',
                          style: TextStyle(
                            color: honey,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          top[i].key,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(top[i].value, currency),
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 4,
                    color: Colors.red.withOpacity(0.6),
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Progreso ahorros ────────────────────────────────────────────────────────

class _SeccionAhorros extends StatelessWidget {
  final AppProvider provider;
  const _SeccionAhorros({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getCategoriasPorTipo('ahorro'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['meta'] as num?)?.toDouble() != null &&
                  (data['meta'] as num).toDouble() > 0;
            })
            .toList();

        if (docs.isEmpty) return const SizedBox();

        return _TarjetaSeccion(
          titulo: 'Progreso de ahorros',
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] as String;
              final disponible = (data['disponible'] as num).toDouble();
              final meta = (data['meta'] as num).toDouble();
              final progreso = (disponible / meta).clamp(0.0, 1.0);
              final metaAlcanzada = disponible >= meta;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          nombre,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(progreso * 100).toInt()}%',
                          style: TextStyle(
                            color: metaAlcanzada ? Colors.green : honey,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(disponible, provider.currency)} / ${CurrencyFormatter.format(meta, provider.currency)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progreso,
                        minHeight: 6,
                        color: metaAlcanzada ? Colors.green : honey,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Movimientos recientes ───────────────────────────────────────────────────

class _SeccionMovimientos extends StatelessWidget {
  final List<QueryDocumentSnapshot> movimientos;
  final String currency;

  const _SeccionMovimientos(
      {required this.movimientos, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (movimientos.isEmpty) {
      return _TarjetaVacia(mensaje: 'Sin movimientos este mes.');
    }

    return _TarjetaSeccion(
      titulo: 'Movimientos',
      child: Column(
        children: movimientos.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tipo = data['tipo'] as String;
          final descripcion = data['descripcion'] as String? ?? '';
          final monto = (data['monto'] as num).toDouble();
          final fecha = data['fecha'] != null
              ? (data['fecha'] as Timestamp).toDate()
              : DateTime.now();
          final esPositivo = monto >= 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descripcion,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${fecha.day}/${fecha.month}/${fecha.year}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${esPositivo ? '+' : ''}${CurrencyFormatter.format(monto.abs(), currency)}',
                  style: TextStyle(
                    color: esPositivo ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Widgets reutilizables ───────────────────────────────────────────────────

class _TarjetaSeccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  final Widget? accion;

  const _TarjetaSeccion({
    required this.titulo,
    required this.child,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (accion != null) accion!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TarjetaVacia extends StatelessWidget {
  final String mensaje;
  const _TarjetaVacia({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(mensaje, style: theme.textTheme.bodySmall),
      ),
    );
  }
}
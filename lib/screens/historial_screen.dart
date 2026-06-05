import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_translator.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;
  int _mesesTendencia = 3;
  
  // Streams aislados para evitar fugas de memoria y lecturas redundantes
  late Stream<QuerySnapshot> _movimientosStream;
  late Stream<QuerySnapshot> _ahorrosStream;

  List<String> _nombresMeses(BuildContext context) => [
    context.tr('mes_1'), context.tr('mes_2'), context.tr('mes_3'),
    context.tr('mes_4'), context.tr('mes_5'), context.tr('mes_6'),
    context.tr('mes_7'), context.tr('mes_8'), context.tr('mes_9'),
    context.tr('mes_10'), context.tr('mes_11'), context.tr('mes_12'),
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    // Aislamos el stream de ahorros para que no se reconecte en cada setState
    _ahorrosStream = provider.firestoreService.getCategoriasPorTipo('ahorro');
    _actualizarStream();
  }

  void _actualizarStream() {
    final provider = context.read<AppProvider>();
    // Calculamos el rango exacto necesario (desde el mes más antiguo de la tendencia hasta el fin del mes seleccionado)
    // Esto evita descargar toda la base de datos de Firebase.
    final inicioRango = DateTime(_anioSeleccionado, _mesSeleccionado - _mesesTendencia + 1, 1);
    final finRango = DateTime(_anioSeleccionado, _mesSeleccionado + 1, 0, 23, 59, 59);

    setState(() {
      _movimientosStream = provider.firestoreService.getMovimientosPorRango(inicioRango, finRango);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();
    final nombresMeses = _nombresMeses(context);

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
        bottomNavigationBar: const BannerAdWidget(),
        appBar: AppBar(title: Text(context.tr('historialAppBar'))),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _movimientosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final todos = snapshot.data?.docs ?? [];

              // Filtramos en memoria solo los del mes actual para los resúmenes y donas
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
                    _SelectorFecha(
                      mes: _mesSeleccionado,
                      anio: _anioSeleccionado,
                      nombresMeses: nombresMeses,
                      onCambio: (mes, anio) {
                        setState(() {
                          _mesSeleccionado = mes;
                          _anioSeleccionado = anio;
                        });
                        // Actualizamos la consulta en Firebase al cambiar la fecha
                        _actualizarStream();
                      },
                    ),
                    const SizedBox(height: 20),
                    _ResumenRapido(
                      movimientos: movimientosMes,
                      currency: provider.currency,
                    ),
                    const SizedBox(height: 20),
                    _SeccionDonut(
                      movimientos: movimientosMes,
                      currency: provider.currency,
                    ),
                    const SizedBox(height: 20),
                    _SeccionTendencia(
                      todos: todos,
                      meses: _mesesTendencia,
                      nombresMeses: nombresMeses,
                      currency: provider.currency,
                      onCambioMeses: (val) {
                        setState(() => _mesesTendencia = val);
                        // Actualizamos la consulta para expandir o reducir los meses descargados
                        _actualizarStream();
                      },
                    ),
                    const SizedBox(height: 20),
                    _SeccionTopSobres(
                      movimientos: movimientosMes,
                      currency: provider.currency,
                    ),
                    const SizedBox(height: 20),
                    _SeccionAhorros(
                      stream: _ahorrosStream,
                      provider: provider,
                    ),
                    const SizedBox(height: 20),
                    _SeccionMovimientos(
                      movimientos: movimientosMes.take(10).toList(),
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
            label: context.tr('resumenIngresos'),
            monto: totalIngresos,
            color: Colors.green,
            currency: currency,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChipResumen(
            label: context.tr('resumenGastos'),
            monto: totalGastos,
            color: Colors.red,
            currency: currency,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChipResumen(
            label: context.tr('resumenSaldo'),
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

    final Map<String, double> gastosPorCategoria = {};
    for (final doc in widget.movimientos) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['tipo'] != 'gasto') continue;
      final nombre = data['categoriaOrigenNombre'] as String? ?? context.tr('otrosLabel');
      final monto = (data['monto'] as num).toDouble().abs();
      gastosPorCategoria[nombre] = (gastosPorCategoria[nombre] ?? 0) + monto;
    }

    if (gastosPorCategoria.isEmpty) {
      return _TarjetaVacia(mensaje: context.tr('donutSinGastos'));
    }

    final total = gastosPorCategoria.values.fold(0.0, (a, b) => a + b);

    final sorted = gastosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final candidatos = sorted
        .where((e) => e.value / total <= 0.10)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    double acumulado = 0;
    final aAgrupar = <MapEntry<String, double>>[];
    for (final entry in candidatos) {
      acumulado += entry.value / total;
      if (acumulado <= 0.15) {
        aAgrupar.add(entry);
      } else {
        break;
      }
    }

    final agruparFinal = aAgrupar.length >= 2 ? aAgrupar : <MapEntry<String, double>>[];
    final clavesBloqueadas = agruparFinal.map((e) => e.key).toSet();

    final Map<String, double> agrupado = {};
    double otros = 0;

    for (final entry in sorted) {
      if (clavesBloqueadas.contains(entry.key)) {
        otros += entry.value;
      } else {
        agrupado[entry.key] = entry.value;
      }
    }

    if (otros > 0) agrupado[context.tr('otrosLabel')] = otros;

    final entries = agrupado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _TarjetaSeccion(
      titulo: context.tr('donutTitulo'),
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
                      _touched = response.touchedSection!.touchedSectionIndex;
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
        if (docFecha.month != fecha.month || docFecha.year != fecha.year) continue;
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

    final spots0 = List.generate(
      datosMeses.length,
      (i) => FlSpot(i.toDouble(), datosMeses[i]['ingresos'] as double),
    );
    final spots1 = List.generate(
      datosMeses.length,
      (i) => FlSpot(i.toDouble(), datosMeses[i]['gastos'] as double),
    );

    return _TarjetaSeccion(
      titulo: context.tr('tendenciaTitulo'),
      accion: Row(
        mainAxisSize: MainAxisSize.min,
        children: [1, 3, 6].map((m) {
          final selected = m == meses;
          return GestureDetector(
            onTap: () => onCambioMeses(m),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.2 == 0 ? 100 : maxY * 1.2,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) {
                  final isIngreso = s.barIndex == 0;
                  return LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isIngreso
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  );
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
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
            lineBarsData: [
              LineChartBarData(
                spots: spots0,
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.green.withOpacity(0.8),
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.green.shade400,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withOpacity(0.06),
                ),
              ),
              LineChartBarData(
                spots: spots1,
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.red.withOpacity(0.8),
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.red.shade400,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withOpacity(0.06),
                ),
              ),
            ],
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
      final nombre = data['categoriaOrigenNombre'] as String? ?? context.tr('sinNombre');
      final monto = (data['monto'] as num).toDouble().abs();
      gastosPorSobre[nombre] = (gastosPorSobre[nombre] ?? 0) + monto;
    }

    if (gastosPorSobre.isEmpty) {
      return _TarjetaVacia(mensaje: context.tr('topSobresSinGastos'));
    }

    final sorted = gastosPorSobre.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final maxMonto = top.first.value;
    final total = top.fold(0.0, (sum, e) => sum + e.value);

    final colores = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade400,
    ];

    return _TarjetaSeccion(
      titulo: context.tr('topSobresTitulo'),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(top.length, (i) {
              final pct = top[i].value / maxMonto;
              final maxBarHeight = 64.0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < top.length - 1 ? 8 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${(top[i].value / total * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colores[i],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: maxBarHeight * pct,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colores[i].withOpacity(0.5),
                                colores[i],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(top.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < top.length - 1 ? 8 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              top[i].key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(top[i].value, currency),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colores[i],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

}

// ─── Progreso ahorros ────────────────────────────────────────────────────────

class _SeccionAhorros extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final AppProvider provider;
  
  const _SeccionAhorros({required this.stream, required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['meta'] as num?)?.toDouble() != null &&
              (data['meta'] as num).toDouble() > 0;
        }).toList();

        if (docs.isEmpty) return const SizedBox();

        return _TarjetaSeccion(
          titulo: context.tr('progresoAhorrosTitulo'),
          child: _AhorrosCarousel(docs: docs, provider: provider),
        );
      },
    );
  }
}

class _AhorrosCarousel extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final AppProvider provider;

  const _AhorrosCarousel({required this.docs, required this.provider});

  @override
  State<_AhorrosCarousel> createState() => _AhorrosCarouselState();
}

class _AhorrosCarouselState extends State<_AhorrosCarousel> {
  int _pagina = 0;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final docs = widget.docs;

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _controller,
            itemCount: docs.length,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final nombre = data['nombre'] as String;
              final disponible = (data['disponible'] as num).toDouble();
              final meta = (data['meta'] as num).toDouble();
              final progreso = (disponible / meta).clamp(0.0, 1.0);
              final metaAlcanzada = disponible >= meta;
              final color = metaAlcanzada ? Colors.green.shade400 : honey;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: progreso,
                                strokeWidth: 7,
                                backgroundColor: theme.colorScheme.surface,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(progreso * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                                if (metaAlcanzada)
                                  Icon(Icons.check_rounded,
                                      size: 12, color: color),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.format(
                                  disponible, widget.provider.currency),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            Text(
                              context.tr('deMeta').replaceAll('{meta}',
                                  CurrencyFormatter.format(
                                      meta, widget.provider.currency)),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (docs.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(docs.length, (i) {
              final activo = i == _pagina;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: activo ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activo
                      ? honey
                      : theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
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
      return _TarjetaVacia(mensaje: context.tr('sinMovimientosMes'));
    }

    return _TarjetaSeccion(
      titulo: context.tr('movimientosTitulo'),
      child: Column(
        children: movimientos.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final descripcion = data['descripcion'] as String? ?? '';
          final tipo = data['tipo'] as String? ?? '';
          final monto = (data['monto'] as num).toDouble();
          final fecha = data['fecha'] != null
              ? (data['fecha'] as Timestamp).toDate()
              : DateTime.now();
          final esPositivo = monto >= 0;
          final color = esPositivo ? Colors.green.shade400 : Colors.red.shade400;

          IconData icono;
          switch (tipo) {
            case 'ingreso':
              icono = Icons.arrow_downward_rounded;
              break;
            case 'gasto':
              icono = Icons.arrow_upward_rounded;
              break;
            case 'destinar':
              icono = Icons.swap_horiz_rounded;
              break;
            case 'reparto':
              icono = Icons.call_split_rounded;
              break;
            default:
              icono = Icons.circle_outlined;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descripcion.isEmpty ? context.tr(tipo) : descripcion,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${fecha.day}/${fecha.month}/${fecha.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${esPositivo ? '+' : '-'}${CurrencyFormatter.format(monto.abs(), currency)}',
                  style: TextStyle(
                    color: color,
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

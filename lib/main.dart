import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  return runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: BulletChart(),
    );
  }
}

class BulletChart extends StatefulWidget {
  BulletChart({Key? key}) : super(key: key);

  @override
  _BulletChartState createState() => _BulletChartState();
}

class _BulletChartState extends State<BulletChart> {
  late List<_StockData> data;

  @override
  void initState() {
    data = [
      _StockData('Product A', 135, 140, 100, 120, 150),
      _StockData('Product B', 190, 220, 150, 180, 210),
      _StockData('Product C', 175, 180, 130, 160, 190),
      _StockData('Product D', 195, 200, 130, 170, 210),
      _StockData('Product E', 125, 120, 50, 70, 100),
      _StockData('Product F', 205, 180, 140, 170, 210),
      _StockData('Product G', 132, 140, 100, 120, 150),
      _StockData('Product H', 88, 80, 50, 70, 100),
      _StockData('Product I', 215, 220, 150, 190, 220),
      _StockData('Product J', 185, 200, 140, 170, 210),
      _StockData('Product K', 208, 200, 150, 190, 220),
      _StockData('Product L', 128, 140, 100, 120, 150),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SfCartesianChart(
        margin: EdgeInsets.all(40),
        primaryXAxis: CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          interval: 50,
          axisLabelFormatter: (AxisLabelRenderDetails args) {
            return ChartAxisLabel('\$' + args.text + 'K', args.textStyle);
          },
        ),
        series: <CartesianSeries<_StockData, String>>[
          ColumnSeries(
            dataSource: data,
            xValueMapper: (_StockData data, int index) => data.product,
            yValueMapper: (_StockData data, int index) => data.current,
            color: Colors.blue.withOpacity(0.8),
            animationDuration: 0,
            onCreateRenderer: (ChartSeries<_StockData, String> series) {
              return _ColumnSeriesRenderer();
            },
          ),
        ],
      ),
    );
  }
}

class _ColumnSeriesRenderer extends ColumnSeriesRenderer<_StockData, String> {
  @override
  ColumnSegment<_StockData, String> createSegment() => _ColumnSegment();
}

class _ColumnSegment extends ColumnSegment<_StockData, String> {
  RRect? _highRect;
  RRect? _midRect;
  RRect? _lowRect;

  void _reset() {
    _highRect = null;
    _midRect = null;
    _lowRect = null;
    segmentRect = null;
    points.clear();
  }

  @override
  void transformValues() {
    if (series.dataSource == null || series.dataSource!.isEmpty) {
      return;
    }

    _reset();
    final Function(num x, num y) transformX = series.pointToPixelX;
    final Function(num x, num y) transformY = series.pointToPixelY;
    final _StockData data = series.dataSource![currentSegmentIndex];
    final BorderRadius borderRadius = series.borderRadius;
    final num left = x + series.sbsInfo.minimum;
    final num right = x + series.sbsInfo.maximum;
    final num high = data.high;
    final num mid = data.mid;
    final num low = data.low;
    final num goal = data.goal;
    final double bottomX = transformX(right, bottom);
    final double bottomY = transformY(right, bottom);

    // Calculate low range rectangle from the bottom.
    final double lowRectTop = transformY(left, low);
    final double lowRectBottom = bottomY;
    _lowRect = toRRect(transformX(left, low), lowRectTop, bottomX,
        lowRectBottom, borderRadius);

    // Calculate mid range rectangle from the low rect.
    final double midRectTop = transformY(left, mid);
    final double midRectBottom = lowRectTop;
    _midRect = toRRect(transformX(left, mid), midRectTop, bottomX,
        midRectBottom, borderRadius);

    // Calculate high range rectangle from the mid rect.
    final double highRectTop = transformY(left, high);
    final double highRectBottom = midRectTop;
    _highRect = toRRect(transformX(left, high), highRectTop, bottomX,
        highRectBottom, borderRadius);

    // Calculate current range rectangle from the bottom.
    final Rect deflatedRect =
        _deflate(transformX(left, y), transformY(left, y), bottomX, bottomY);
    segmentRect = toRRect(deflatedRect.left, deflatedRect.top,
        deflatedRect.right, deflatedRect.bottom, borderRadius);

    // Calculate goal value points.
    points
      ..add(Offset(transformX(left, goal), transformY(left, goal)))
      ..add(Offset(transformX(right, goal), transformY(right, goal)));
  }

  RRect toRRect(double left, double top, double right, double bottom,
      BorderRadius borderRadius) {
    if (top > bottom) {
      final double temp = top;
      top = bottom;
      bottom = temp;
    }

    if (left > right) {
      final double temp = left;
      left = right;
      right = temp;
    }

    return RRect.fromLTRBAndCorners(
      left,
      top,
      right,
      bottom,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );
  }

  Rect _deflate(double left, double top, double right, double bottom) {
    const double delta = 0.3;
    if (series.isTransposed) {
      final double height = (bottom - top) * delta;
      return Rect.fromLTRB(left, top - height, right, bottom + height);
    } else {
      final double width = (right - left) * delta;
      return Rect.fromLTRB(left + width, top, right - width, bottom);
    }
  }

  @override
  void onPaint(Canvas canvas) {
    Paint paint = getFillPaint();

    // Draws low range rectangle.
    if (_lowRect != null) {
      paint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      if (paint.color != Colors.transparent && !_lowRect!.isEmpty) {
        canvas.drawRRect(_lowRect!, paint);
      }
    }

    // Draws mid range rectangle.
    if (_midRect != null) {
      paint = Paint()
        ..color = Colors.green.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      if (paint.color != Colors.transparent && !_midRect!.isEmpty) {
        canvas.drawRRect(_midRect!, paint);
      }
    }

    // Draws high range rect.
    if (_highRect != null) {
      paint = Paint()
        ..color = Colors.green.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      if (paint.color != Colors.transparent && !_highRect!.isEmpty) {
        canvas.drawRRect(_highRect!, paint);
      }
    }

    // Draws current range rectangle.
    if (segmentRect != null) {
      paint = getFillPaint();
      if (paint.color != Colors.transparent && !segmentRect!.isEmpty) {
        canvas.drawRRect(segmentRect!, paint);
      }
    }

    // Draws goal of horizontal/vertical line.
    if (points.isNotEmpty && points.length == 2) {
      paint = Paint()
        ..color = Colors.red
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(points[0], points[1], paint);
    }
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }
}

class _StockData {
  _StockData(
    this.product,
    this.current,
    this.goal,
    this.low,
    this.mid,
    this.high,
  );

  final String product;
  final double current;
  final double goal;
  final double low;
  final double mid;
  final double high;
}

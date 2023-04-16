/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

import '../../../pdf.dart';
import '../flex.dart';
import '../geometry.dart';
import '../page.dart';
import '../widget.dart';
import 'chart.dart';
import 'grid_axis.dart';
import 'grid_cartesian.dart';
import 'point_chart.dart';

class BarDataSet<T extends PointChartValue> extends PointDataSet<T> {
  BarDataSet({
    required List<T> data,
    String? legend,
    this.borderColor,
    this.borderWidth = 1.5,
    PdfColor color = PdfColors.blue,
    bool? drawBorder,
    this.drawSurface = true,
    this.surfaceOpacity = 1,
    this.width = 10,
    this.offset = 0,
    this.axis = Axis.horizontal,
    PdfColor? pointColor,
    double pointSize = 3,
    bool drawPoints = false,
    BuildCallback? shape,
    Widget Function(Context context, T value)? buildValue,
    ValuePosition valuePosition = ValuePosition.auto,
    this.format,
    this.labelColor,
  })  : drawBorder = drawBorder ?? borderColor != null && color != borderColor,
        assert((drawBorder ?? borderColor != null && color != borderColor) ||
            drawSurface),
        super(
          legend: legend,
          color: pointColor ?? color,
          data: data,
          buildValue: buildValue,
          drawPoints: drawPoints,
          pointSize: pointSize,
          shape: shape,
          valuePosition: valuePosition,
        );

  final bool drawBorder;
  final PdfColor? borderColor;
  final double borderWidth;

  final bool drawSurface;

  final double surfaceOpacity;

  final double width;
  final double offset;

  final Axis axis;

  final GridAxisFormat? format;
  final PdfColor? labelColor;

  void _drawSurface(Context context, ChartGrid grid, T value) {
    switch (axis) {
      case Axis.horizontal:
        final y = (grid is CartesianGrid) ? grid.xAxisOffset : 0.0;
        final p = grid.toChart(value.point);
        final x = (p.x == double.infinity || p.x.isNaN
            ? 0.0 + offset + width
            : p.x + offset - width / 2);
        final height = p.y - y;

        context.canvas.drawRect(x, y, width, height);

        break;
      case Axis.vertical:
        final x = (grid is CartesianGrid) ? grid.yAxisOffset : 0.0;
        final p = grid.toChart(value.point);
        final y = p.y + offset - width / 2;
        final height = p.x - x;

        context.canvas.drawRect(x, y, height, width);
        break;
    }
  }

  void _drawLabel(Context context, ChartGrid grid, T value) {
    switch (axis) {
      case Axis.horizontal:
        final y = (grid is CartesianGrid) ? grid.xAxisOffset : 0.0;
        final p = grid.toChart(value.point);
        final x = (p.x == double.infinity || p.x.isNaN
            ? 0.0 + offset + width
            : p.x + offset - width / 2);
        final height = p.y - y;

        final font = context.canvas.defaultFont!;
        final text = format?.call(value.y) ?? value.y.toString();
        const fontSize = 12.0;
        const angle = pi / 4;

        final metrics = font.stringMetrics(text) * fontSize;

        context.canvas
          ..saveContext()
          ..setFillColor(labelColor ?? PdfColors.black)
          ..setTransform(
            Matrix4.identity()
              ..translate(x, y + height + 5.0) // Text position
              ..rotateZ(angle)
              ..translate(-metrics.left,
                  -metrics.top - metrics.height / 2), // Center of Rotation
          )
          ..drawString(
            font,
            fontSize,
            text,
            0,
            0,
          )
          ..setFillColor(color)
          ..restoreContext();

        break;
      case Axis.vertical:
        final x = (grid is CartesianGrid) ? grid.yAxisOffset : 0.0;
        final p = grid.toChart(value.point);
        final y = p.y + offset - width / 2;
        final height = p.x - x;

        context.canvas.drawRect(x, y, height, width);
        break;
    }
  }

  @override
  void layout(Context context, BoxConstraints constraints,
      {bool parentUsesSize = false}) {
    box = PdfRect.fromPoints(PdfPoint.zero, constraints.biggest);
  }

  @override
  void paint(Context context) {
    super.paint(context);

    if (data.isEmpty) {
      return;
    }

    final grid = Chart.of(context).grid;

    if (drawSurface) {
      for (final value in data) {
        _drawSurface(context, grid, value);
      }

      if (surfaceOpacity != 1) {
        context.canvas
          ..saveContext()
          ..setGraphicState(
            PdfGraphicState(opacity: surfaceOpacity),
          );
      }

      context.canvas
        ..setFillColor(color)
        ..fillPath();

      if (surfaceOpacity != 1) {
        context.canvas.restoreContext();
      }
    }

    if (drawBorder) {
      for (final value in data) {
        _drawSurface(context, grid, value);
      }

      context.canvas
        ..setStrokeColor(borderColor ?? color)
        ..setLineWidth(borderWidth)
        ..strokePath();
    }

    for (final value in data) {
      _drawLabel(context, grid, value);
    }
  }

  @override
  ValuePosition automaticValuePosition(
    PdfPoint point,
    PdfPoint size,
    PdfPoint? previous,
    PdfPoint? next,
  ) {
    final pos = super.automaticValuePosition(point, size, previous, next);
    if (pos == ValuePosition.right || pos == ValuePosition.left) {
      return ValuePosition.top;
    }

    return pos;
  }
}

/**
 * MIT License
 *
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

interface IOptions {
  width?: number;
  height?: number;
  color?: string;
  bgColor?: string;
  scale?: number;
  openSmooth?: boolean;
  minWidth?: number;
  maxWidth?: number;
  minSpeed?: number;
  maxWidthDiffRate?: number;
  maxHistoryLength?: number;
}
interface Point {
  x: number;
  y: number;
}

interface IPoint extends Point {
  t: number;
  speed: number;
  distance: number;
  lineWidth: number;
}

interface CalcPoint extends IPoint {
  lastX1: number;
  lastY1: number;
  lastX2: number;
  lastY2: number;
  perLineWidth: number;
  isFirstPoint: boolean;
}

interface IRadianData {
  val: number;
  pos: -1 | 1;
}

class SmoothSignature {
  constructor(ctx: CanvasRenderingContext2D, options: IOptions) {
    this.ctx = ctx;
  }
  ctx: CanvasRenderingContext2D;
  scale = 1;
  color = 'black';
  bgColor  = '';
  canDraw = false;
  openSmooth = true;
  minWidth = 2;
  maxWidth = 6;
  minSpeed = 1.5;
  maxWidthDiffRate = 20;
  points: IPoint[] = [];
  canAddHistory = true;
  historyList: string[] = [];
  maxHistoryLength = 20;

  init(options: IOptions = {}) {
    this.scale = options.scale || this.scale;
    this.color = options.color || this.color;
    this.bgColor = options.bgColor || this.bgColor;
    this.openSmooth = true;
    this.minWidth = options.minWidth || this.minWidth;
    this.maxWidth = options.maxWidth || this.maxWidth;
    this.minSpeed = options.minSpeed || this.minSpeed;
    this.maxWidthDiffRate = options.maxWidthDiffRate || this.maxWidthDiffRate;
    this.maxHistoryLength = options.maxHistoryLength || this.maxHistoryLength;
    this.drawBgColor();
  }

  public onDrawStart = (e: TouchEvent) => {
    this.canDraw = true;
    this.canAddHistory = true;
    this.ctx.strokeStyle = this.color;
    this.initPoint(e);
  }

  public onDrawMove = (e: TouchEvent) => {
    this.ctx.lineCap = 'round';
    this.ctx.lineJoin = 'round';
    if (!this.canDraw) return;
    this.initPoint(e);
    if (this.points.length < 2) return;
    const point = this.points.slice(-1)[0];
    const prePoint = this.points.slice(-2, -1)[0];
    this.drawSmoothLine(prePoint as CalcPoint, point as CalcPoint);
  }

  public onDrawEnd = () => {
    if (!this.canDraw) return;
    this.canDraw = false;
    this.canAddHistory = true;
    this.points = [];
  }

  getLineWidth(speed: number) {
    const minSpeed = this.minSpeed > 10 ? 10 : this.minSpeed < 1 ? 1 : this.minSpeed;
    const addWidth = (this.maxWidth - this.minWidth) * speed / minSpeed;
    const lineWidth = Math.max(this.maxWidth - addWidth, this.minWidth);
    return Math.min(lineWidth, this.maxWidth);
  }

  getRadianData(x1: number, y1: number, x2: number, y2: number): IRadianData {
    const dis_x = x2 - x1;
    const dis_y = y2 - y1;
    if (dis_x === 0) {
      return { val: 0, pos: -1 };
    }
    if (dis_y === 0) {
      return { val: 0, pos: 1 };
    }
    const val = Math.abs(Math.atan(dis_y / dis_x));
    if (x2 > x1 && y2 < y1 || (x2 < x1 && y2 > y1)) {
      return { val, pos: 1 };
    }
    return { val, pos: -1 };
  }

  getRadianPoints(radianData: IRadianData, x: number, y: number, halfLineWidth: number): [Point, Point] {
    if (radianData.val === 0) {
      if (radianData.pos === 1) {
        return [
          { x, y: y + halfLineWidth },
          { x, y: y - halfLineWidth }
        ]
      }
      return [
        { y, x: x + halfLineWidth },
        { y, x: x - halfLineWidth }
      ]
    }
    const dis_x = Math.sin(radianData.val) * halfLineWidth;
    const dis_y = Math.cos(radianData.val) * halfLineWidth;
    if (radianData.pos === 1) {
      return [
        { x: x + dis_x, y: y + dis_y },
        { x: x - dis_x, y: y - dis_y }
      ]
    }
    return [
      { x: x + dis_x, y: y - dis_y },
      { x: x - dis_x, y: y + dis_y }
    ]
  }

  initPoint(event: TouchEvent) {
    const t = Date.now();
    const prePoint = this.points.slice(-1)[0];
    if (prePoint && prePoint.t === t) {
      return;
    }
    const e = event.touches && event.touches[0];
    const x = e.x;
    const y = e.y;
    if (prePoint && prePoint.x === x && prePoint.y === y) {
      return
    }
    const point: IPoint = {
      x,
      y,
      t,
      lineWidth: 0,
      speed: 0,
      distance: 0
    }
    if (prePoint) {
      const prePoint2 = this.points.slice(-2, -1)[0];
      point.distance = Math.sqrt(Math.pow(point.x - prePoint.x, 2) + Math.pow(point.y - prePoint.y, 2));
      point.speed = point.distance / ((point.t - prePoint.t) || 0.1);
      point.lineWidth = this.getLineWidth(point.speed);
      if (prePoint2 && prePoint2.lineWidth && prePoint.lineWidth) {
        const rate = (point.lineWidth - prePoint.lineWidth) / prePoint.lineWidth;
        let maxRate = this.maxWidthDiffRate / 100;
        maxRate = maxRate > 1 ? 1 : maxRate < 0.01 ? 0.01 : maxRate;
        if (Math.abs(rate) > maxRate) {
          const per = rate > 0 ? maxRate : -maxRate;
          point.lineWidth = prePoint.lineWidth * (1 + per);
        }
      }
    }
    this.points.push(point);
    this.points = this.points.slice(-3);
  }

  public drawSmoothLine(prePoint: CalcPoint, point: CalcPoint) {
    const dis_x = point.x - prePoint.x;
    const dis_y = point.y - prePoint.y;
    if (Math.abs(dis_x) + Math.abs(dis_y) <= this.scale) {
      point.lastX1 = point.lastX2 = prePoint.x + (dis_x * 0.5);
      point.lastY1 = point.lastY2 = prePoint.y + (dis_y * 0.5);
    } else {
      point.lastX1 = prePoint.x + (dis_x * 0.3);
      point.lastY1 = prePoint.y + (dis_y * 0.3);
      point.lastX2 = prePoint.x + (dis_x * 0.7);
      point.lastY2 = prePoint.y + (dis_y * 0.7);
    }
    point.perLineWidth = (prePoint.lineWidth + point.lineWidth) / 2;
    if (typeof prePoint.lastX1 === 'number') {
      this.drawCurveLine(prePoint.lastX2, prePoint.lastY2, prePoint.x, prePoint.y, point.lastX1, point.lastY1, point.perLineWidth);
      if (prePoint.isFirstPoint) return;
      if (prePoint.lastX1 === prePoint.lastX2 && prePoint.lastY1 === prePoint.lastY2) return;
      const data = this.getRadianData(prePoint.lastX1, prePoint.lastY1, prePoint.lastX2, prePoint.lastY2);
      const points1 = this.getRadianPoints(data, prePoint.lastX1, prePoint.lastY1, prePoint.perLineWidth / 2);
      const points2 = this.getRadianPoints(data, prePoint.lastX2, prePoint.lastY2, point.perLineWidth / 2);
      this.drawTrapezoid(points1[0], points2[0], points2[1], points1[1]);
    } else {
      point.isFirstPoint = true;
    }
  }

  drawCurveLine(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, lineWidth: number) {
    this.ctx.lineWidth = lineWidth;
    this.ctx.beginPath();
    this.ctx.moveTo(x1, y1);
    this.ctx.quadraticCurveTo(
      x2, y2, x3, y3
    );
    this.ctx.strokeStyle = this.color;
    this.ctx.stroke();
  }

  drawTrapezoid(point1: Point, point2: Point, point3: Point, point4: Point) {
    this.ctx.beginPath();
    this.ctx.moveTo(point1.x, point1.y);
    this.ctx.lineTo(point2.x, point2.y);
    this.ctx.lineTo(point3.x, point3.y);
    this.ctx.lineTo(point4.x, point4.y);
    this.ctx.fillStyle = this.color;
    this.ctx.fill();
  }

  drawBgColor() {
    if (!this.bgColor) return;
    this.ctx.fillStyle = this.bgColor;
    this.ctx.fillRect(0, 0, this.ctx.width, this.ctx.height);
  }

}

export default SmoothSignature;

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

import { RNComponentContext, RNOHLogger, RNViewBase } from '@rnoh/react-native-openharmony';
import { RNC } from "@rnoh/react-native-openharmony/generated"
import SmoothSignature from './signature';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import image from '@ohos.multimedia.image';
import window from '@ohos.window';
import util from '@ohos.util';


const signatureDir = 'saved_signature';
const signatureFileName = 'signature.png';
const prefix = 'data:image/png;base64,';


@Component
export struct SignatureCaptureArkView {
  public static readonly NAME = RNC.RSSignatureArkView.NAME
  public ctx!: RNComponentContext
  public tag: number = 0;
  // canvas
  private setting: RenderingContextSettings = new RenderingContextSettings(true);
  private context2D: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.setting);
  sign = new SmoothSignature(this.context2D, {});
  @State private descriptorWrapper: RNC.RSSignatureArkView.DescriptorWrapper = {
  } as RNC.RSSignatureArkView.DescriptorWrapper
  private eventEmitter: RNC.RSSignatureArkView.EventEmitter | undefined = undefined
  private cleanUpCallbacks: (() => void)[] = []
  private logger!: RNOHLogger;
  private windowClass!: window.Window;
  private imagePacker = image.createImagePacker();
  private base64Helper = new util.Base64Helper();


 aboutToAppear() {
   // 初始化logger
   this.logger = this.ctx.logger.clone('SignatureCapture');

   this.eventEmitter = new RNC.RSSignatureArkView.EventEmitter(this.ctx.rnInstance, this.tag)

   this.onDescriptorWrapperChange(this.ctx.descriptorRegistry.findDescriptorWrapperByTag<RNC.RSSignatureArkView.DescriptorWrapper>(this.tag)!)

   this.cleanUpCallbacks.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (_descriptor, newDescriptorWrapper) => {
        this.logger.info('signature capture descriptor change!');
        this.onDescriptorWrapperChange(newDescriptorWrapper! as RNC.RSSignatureArkView.DescriptorWrapper)
      }
   ));

   const cmdReceiver = new RNC.RSSignatureArkView.CommandReceiver(this.ctx.componentCommandReceiver, this.tag);

   this.cleanUpCallbacks.push(cmdReceiver.subscribe("saveImage", (argv) => {
     this.logger.info('==== command saveImage ====' + JSON.stringify(argv));
     this.save();
   }))
   this.cleanUpCallbacks.push(cmdReceiver.subscribe("resetImage", (argv) => {
     this.logger.info('==== command resetImage ====')
     this.reset();
   }))
   this.setProps();
  }

  private setProps() {
    this.setMinWidth();
    this.setMaxWidth();
    this.setStrokeColor();
    this.setBackgroundColor();
    this.setViewMode(this.descriptorWrapper.props.viewMode);
  }

  private async setWindowClass(): Promise<void> {
    let context = this.ctx.uiAbilityContext;
    this.windowClass = await window.getLastWindow(context);
  }

  private async setViewMode(viewMode: "portrait" | "landscape") {
    if (!this.windowClass) {
      await this.setWindowClass();
    };
    try {
      await this.windowClass.setPreferredOrientation(
        viewMode === "portrait" ? window.Orientation.PORTRAIT : window.Orientation.LANDSCAPE
      );
    } catch (err) {
      this.logger.info(JSON.stringify(err));
    }
  }

  private setBackgroundColor() {
    this.sign.bgColor = this.descriptorWrapper.props.backgroundColor.toRGBAString();
    this.sign.drawBgColor();
  }

  private setMinWidth() {
    this.sign.minWidth = this.descriptorWrapper.props.minStrokeWidth;
  }

  private setMaxWidth() {
    this.sign.maxWidth = this.descriptorWrapper.props.maxStrokeWidth;
  }

  private setStrokeColor() {
    this.sign.color = this.descriptorWrapper.props.strokeColor.toRGBAString();
  }

  private onDescriptorWrapperChange(descriptorWrapper: RNC.RSSignatureArkView.DescriptorWrapper) {
    this.logger.info('descriptor change!');
    this.descriptorWrapper = descriptorWrapper;
    this.setProps();
  }

  aboutToDisappear() {
    this.cleanUpCallbacks.forEach(cb => cb());
    this.imagePacker.release();
  }

  public onDraw(event: TouchEvent) {
    if (event.touches.length > 1) {
      return;
    };
    switch (event.type) {
      case TouchType.Down:
        this.sign.onDrawStart(event);
        this.eventEmitter?.emit('change', { pathName: '', encoded: '', dragged: true });
      break;
      case TouchType.Move:
        this.sign.onDrawMove(event);
      break;
      case TouchType.Up:
        this.sign.onDrawEnd();
      break;
      case TouchType.Cancel:
      break
    }
  }

  /*
   * 画布重置
   * */
  public reset() {
    this.context2D.clearRect(0, 0, this.context2D.width, this.context2D.height);
    this.sign.drawBgColor();
  }

  private getCanvasPixMap() {
    return this.context2D.getPixelMap(0, 0, this.context2D.width, this.context2D.height);
  }

  /*
   * 根据传入的maxSize参数，对图片大小进行调整
   *
   * */
  private getReSizePm() {
    const pm = this.getCanvasPixMap();
    const maxSize = this.descriptorWrapper.props.maxSize;
    if (maxSize) {
      let width = this.context2D.width;
      let height = this.context2D.height;
      const ratio = width / height;
      if (ratio > 1) {
        width = maxSize;
        height = width / ratio;
      } else {
        height = maxSize;
        width = height * ratio;
      }
      let xScale = width / this.context2D.width / 3.25;
      let yScale = height / this.context2D.height / 3.25;
      pm.scaleSync(xScale, yScale);
    }
    return pm;
  }

  /*
   * 保存文件至files dir
   * */
  async save() {
    const filesDir = this.ctx.uiAbilityContext.filesDir;
    const dirAbsolutePath = `${filesDir}/${signatureDir}`;
    const saveFilePath = `${dirAbsolutePath}/${signatureFileName}`;
    try {
      const isExist = fs.accessSync(saveFilePath, fs.AccessModeType.EXIST);
      if (isExist) {
        fs.unlinkSync(saveFilePath);
      } else {
        fs.mkdirSync(dirAbsolutePath);
      };
      const file = fs.openSync(saveFilePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      const pm = this.getReSizePm();
      const buf = await this.imagePacker.packing(pm, { format: 'image/png', quality: 100 });
      const base64String = this.base64Helper.encodeToStringSync(new Uint8Array(buf));
      fs.writeSync(file.fd, buf);
      fs.closeSync(file.fd);

      this.eventEmitter?.emit('change', {
        pathName: saveFilePath,
        encoded: prefix + base64String,
        dragged: false
      });
    } catch (e) {
      let err: BusinessError = e;
      this.logger.info(`${err.code} ${err.message}`);
    } finally {
      // 保存后会清空canvas，效果对标ios
      this.reset();
    }
  }

  public canvasReady() {
    this.logger.info('canvas ready');
    this.sign.init();
  }

  /*
   * showNativeButtons 是否显示原生按钮，对标ios效果，两个button在画布最右侧并旋转了90°
   * */
  @Builder buildButton() {
    if (this.descriptorWrapper.props.showNativeButtons) {
      Column() {
        Button('Reset').onClick(() => {
          this.reset();
        }).type(ButtonType.Normal)
          .borderRadius(2).backgroundColor('#fff3ecec').fontColor('#0ea5f3').rotate({angle: 90, centerX: 0, centerY: 0}).width(80)
        Button('Save').onClick(() => {
          this.save();
        }).type(ButtonType.Normal)
          .borderRadius(2).backgroundColor('#fff3ecec').fontColor('#0ea5f3').rotate({angle: 90, centerX: 0, centerY: 0}).width(80).translate({y: -40})
      }.position({right: 8}).height('100%').padding({top: 8, bottom: 8}).justifyContent(FlexAlign.SpaceBetween).translate({x: 80})
    }
  }


  /*
   * 绘制showTitleLabel的效果
   *
   * */
  @Builder buildTitleLabel() {
    if (this.descriptorWrapper.props.showTitleLabel) {
      Line().startPoint([30, 24]).endPoint([40, 14]).stroke('#ccc').strokeWidth(1)
      Line().startPoint([30, 14]).endPoint([40, 24]).stroke('#ccc').strokeWidth(1)
      Line().antiAlias(true).strokeDashArray([6])
        .startPoint([30, 30])
        .endPoint([30, this.descriptorWrapper.height - 30])
        .stroke('#ccc')
        .strokeWidth(1)
    }
  }

  build() {
    RNViewBase({ ctx: this.ctx, tag: this.tag }) {
      Canvas(this.context2D)
        .onReady(() => {
          this.canvasReady();
        }).onTouch((event: TouchEvent) => {
        // touch事件event获取坐标，绘制线条
        this.onDraw(event);
      })
        .width(this.descriptorWrapper.width)
        .height(this.descriptorWrapper.height)
        .backgroundColor(this.descriptorWrapper.backgroundColor)
      this.buildTitleLabel();
      this.buildButton();
    }
  }
}

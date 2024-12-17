/*
 * Copyright (c) 2024 Huawei Device Co., Ltd. All rights reserved
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

import type { ViewProps, HostComponent, ProcessedColorValue } from 'react-native';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
import type {
  Float,
  DirectEventHandler,
  WithDefault,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';
import type React from 'react';


export interface OutgoingAndIncomingData {
    rotateClockwise?: WithDefault<boolean, true>;
    square?: WithDefault<boolean, true>;
    saveImageFileInExtStorage?: WithDefault<boolean, true>
    viewMode?: WithDefault<'portrait' | 'landscape', 'portrait'>,
    showBorder?: WithDefault<boolean, true>,
    showNativeButtons?: WithDefault<boolean, true>,
    showTitleLabel?: WithDefault<boolean, true>,
    maxSize?: Int32,
    minStrokeWidth?: WithDefault<Float, 3>,
    maxStrokeWidth?: WithDefault<Float, 6>,
    strokeColor?: ProcessedColorValue | null,
    backgroundColor?: ProcessedColorValue | null
}

export interface SignatureCaptureArkViewNativeProps
  extends ViewProps,
    OutgoingAndIncomingData {
  onChange: DirectEventHandler<{pathName: string, dragged: boolean, encoded: string}>;
}

type NativeType = HostComponent<SignatureCaptureArkViewNativeProps>;

interface NativeCommands {
  saveImage: (
    viewRef: React.ElementRef<NativeType>,
    eventType: string, 
    someOptionalArg?: boolean 
  ) => void; 
  resetImage: (
    viewRef: React.ElementRef<NativeType>,
    eventType: string, 
    someOptionalArg?: boolean 
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['saveImage', 'resetImage'],
});

/**
 * codegen restriction: the result of codegenNativeComponent must be a default export
 */
export default codegenNativeComponent<SignatureCaptureArkViewNativeProps>(
  'RSSignatureArkView'
) as HostComponent<SignatureCaptureArkViewNativeProps>

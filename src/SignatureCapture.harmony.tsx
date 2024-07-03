import React, { useRef } from "react";
import {
    NativeSyntheticEvent,
    ViewStyle,
    StyleProp,
    UIManager,
    findNodeHandle,
    ProcessedColorValue,
    processColor,
  } from "react-native";
  import SignatureCaptureNativeComponent from './SignatureCaptureNativeComponent';
  
  export type SignatureComponentRef = {
     saveImage: () => void
     resetImage: () => void
   };

const SignatureCaptureHarmonyComponent = React.forwardRef<
  SignatureComponentRef,
  {
    backgroundColor?: ProcessedColorValue;
    onSaveEvent?: (ev: {pathName: string, encoded: string}) => void
    onDragEvent?: (ev: {dragged: boolean}) => void
    minStrokeWidth?: number
    maxStrokeWidth?: number
    strokeColor?: ProcessedColorValue
    showTitleLabel?: boolean
    showNativeButtons?: boolean
    showBorder?:boolean
    viewMode?: 'portrait' | 'landscape'
    maxSize?: number
    styles?: StyleProp<ViewStyle>
  }
>(( props, ref) => {
  const nativeRef = useRef<any>(null);

  React.useImperativeHandle(
    ref,
    () => ({
      saveImage() {
        if (nativeRef?.current) {
          UIManager.dispatchViewManagerCommand(
            findNodeHandle(nativeRef.current),
            "saveImage",
            []
          );
        }
      },
      resetImage() {
        if (nativeRef?.current) {
          UIManager.dispatchViewManagerCommand(
            findNodeHandle(nativeRef.current),
            "resetImage",
            []
          );
        }
      },
    }),
    []
  );

  const borderStyle: StyleProp<ViewStyle> = {
    borderWidth: 1,
    borderStyle: 'dashed',
    borderColor: '#ccc'
  }
  
  const onChange = (ev: NativeSyntheticEvent<{pathName: string, encoded: string} | {dragged: boolean}>) => {
    const nativeEvent = ev.nativeEvent; 
    
    if ('pathName' in nativeEvent) {
      if (!props.onSaveEvent) { return; }
      nativeEvent.pathName && props.onSaveEvent({
        pathName: nativeEvent.pathName,
        encoded: nativeEvent.encoded
      })
    }
    if ('dragged' in nativeEvent) {
      if (!props.onDragEvent) { return; }
      nativeEvent.dragged && props.onDragEvent({
        dragged: nativeEvent.dragged
      })
    }
  }
  
  const processedStrokeColor = processColor(props.strokeColor ?? 'black');
  const processedBackgroundColor = processColor(props.backgroundColor);

  
  const colorHandleProps = {
    ...props, strokeColor: processedStrokeColor, backgroundColor: processedBackgroundColor
  }
  
  
  return (
    <SignatureCaptureNativeComponent
      ref={nativeRef}
      style={[props.styles, props.showBorder ? borderStyle : {}]}
      onChange={onChange}
      {...colorHandleProps}
    />
  );
})

export default SignatureCaptureHarmonyComponent;

/*
 * Copyright (c) 2024 Huawei Device Co., Ltd. All rights reserved
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

import React from "react";
import type { ProcessedColorValue, StyleProp, ViewProps } from "react-native";
var ReactNative = require('react-native');
var {
    UIManager,
    DeviceEventEmitter
} = ReactNative;

import RSSignatureView from './SignatureCaptureNativeComponent'; 

type SignProps = {
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
    style?: StyleProp<ViewProps>
}

class SignatureCapture extends React.Component<SignProps> {
    
    private subscriptions: Array<{remove: () => void}> = [];
    
    constructor(props: SignProps) {
        super(props);
        this.onChange = this.onChange.bind(this);
    }
    
    borderStyle = { borderWidth: 1, borderStyle: 'dashed', borderColor: '#ccc' }

    onChange(event: any) {

        if(event.nativeEvent.pathName){

            if (!this.props.onSaveEvent) {
                return;
            }
            this.props.onSaveEvent({
                pathName: event.nativeEvent.pathName,
                encoded: event.nativeEvent.encoded,
            });
        }

        if(event.nativeEvent.dragged){
            if (!this.props.onDragEvent) {
                return;
            }
            this.props.onDragEvent({
                dragged: event.nativeEvent.dragged
            });
        }
    }

    componentDidMount() {
        if (this.props.onSaveEvent) {
            let sub = DeviceEventEmitter.addListener(
                'onSaveEvent',
                this.props.onSaveEvent
            );
            this.subscriptions.push(sub);
        }

        if (this.props.onDragEvent) {
            let sub = DeviceEventEmitter.addListener(
                'onDragEvent',
                this.props.onDragEvent
            );
            this.subscriptions.push(sub);
        }
    }

    componentWillUnmount() {
        this.subscriptions.forEach((sub: any) => sub.remove());
        this.subscriptions = [];
    }

    render() {
        let borderStyle = this.props.showBorder ? this.borderStyle : {};
        let finalStyle = Array.isArray(this.props.style) ? [...this.props.style, borderStyle] : [this.props.style, borderStyle];

        const processColorProps = {
            ...this.props, backgroundColor: ReactNative.processColor(this.props.backgroundColor),
            strokeColor: ReactNative.processColor(this.props.strokeColor), style: finalStyle
        }
        return (
            <RSSignatureView {...processColorProps} onChange={this.onChange} />
        );
    }

    saveImage() {
        UIManager.dispatchViewManagerCommand(
            ReactNative.findNodeHandle(this),
            'saveImage',
            [],
        );
    }

    resetImage() {
        UIManager.dispatchViewManagerCommand(
            ReactNative.findNodeHandle(this),
            'resetImage',
            [],
        );
    }
}


export default SignatureCapture;
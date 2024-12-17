/*
 * Copyright (c) 2024 Huawei Device Co., Ltd. All rights reserved
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

import SignatureCapture from 'react-native-signature-capture';
import SignatureCaputreHarmony from './SignatureCapture.harmony';
import { Platform } from 'react-native';

const isIosAndroid = Platform.OS === 'ios' || Platform.OS === 'android';

const exportComp = isIosAndroid ? SignatureCapture : SignatureCaputreHarmony;

export default exportComp;
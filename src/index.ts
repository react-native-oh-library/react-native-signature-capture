import SignatureCapture from 'react-native-signature-capture';
import SignatureCaputreHarmony from './SignatureCapture.harmony';
import { Platform } from 'react-native';

const isIosAndroid = (() => Platform.OS === 'ios' || Platform.OS === 'android')();

const exportComp = isIosAndroid ? SignatureCapture : SignatureCaputreHarmony;

export default exportComp;
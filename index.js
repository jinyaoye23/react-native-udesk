
import { NativeModules } from 'react-native';
const { RNReactNativeUdesk } = NativeModules;

export default class UdeskAPI {
    static initSDK(UDESK_DOMAIN, UDESK_APPKEY, UDESK_APPID, userInfo) {
        RNReactNativeUdesk.initSDK(UDESK_DOMAIN, UDESK_APPKEY, UDESK_APPID, userInfo)
    }

    static setUserInfo(options) {
        RNReactNativeUdesk.setUserInfo(options)
    }

    static entryChat(imageUrl) {
        RNReactNativeUdesk.entryChat(imageUrl)
    }

    static getUnReadCount(callback) {
        RNReactNativeUdesk.getUnReadCount(callback)
    }

    static logoutUdesk() {
        RNReactNativeUdesk.logoutUdesk()
    }
    
    static openSDkPush() {
        RNReactNativeUdesk.openSDkPush()
    }

    static closeSDkPush() {
        RNReactNativeUdesk.closeSDkPush()
    }

}


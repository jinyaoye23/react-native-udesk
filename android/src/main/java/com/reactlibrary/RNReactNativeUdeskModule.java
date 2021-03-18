
package com.reactlibrary;

import android.os.Handler;
import android.text.TextUtils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import cn.udesk.UdeskSDKManager;
import cn.udesk.callback.PageBackCallBack;
import cn.udesk.config.UdeskConfig;
import cn.udesk.model.NavigationMode;
import udesk.core.UdeskCallBack;
import udesk.core.UdeskConst;
import udesk.core.UdeskHttpFacade;

public class RNReactNativeUdeskModule extends ReactContextBaseJavaModule {
    private String appId, appKey, appDomain, sdktoken, uuid;
    private Map<String, String> info;
    private UdeskConfig.Builder builder;

    private final ReactApplicationContext mReactContext;

    private List<NavigationMode> getNavigations() {
        List<NavigationMode> modes = new ArrayList<>();
        NavigationMode navigationMode1 = new NavigationMode("提交工单", 1);
//        NavigationMode navigationMode2 = new NavigationMode("发送文本", 2);
        modes.add(navigationMode1);
        return modes;
    }

    public RNReactNativeUdeskModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.mReactContext = reactContext;
    }

    @Override
    public String getName() {
        return "RNReactNativeUdesk";
    }


    @ReactMethod
    public void initSDK(String appDomain, String appKey, String appId, final ReadableMap options) {

        try {

            this.appDomain = appDomain;
            this.appKey = appKey;
            this.appId = appId;
            this.builder = new UdeskConfig.Builder();

            UdeskSDKManager.getInstance().initApiKey(mReactContext.getApplicationContext(), this.appDomain, this.appKey, this.appId);
            setBuilder();
            setUserInfo(options);


            openSDkPush();//开启推送
            return;
        } catch (Exception e) {

        }
    }

    @ReactMethod
    public void openSDkPush() {
        try {
            builder.setUserSDkPush(true);

//        UdeskSDKManager.getInstance().setRegisterId(mReactContext.getApplicationContext(), "12");
            UdeskHttpFacade.getInstance().sdkPushStatus(appDomain, appKey, sdktoken, "on", uuid, appId, new UdeskCallBack() {
                @Override
                public void onSuccess(String s) {
                }

                @Override
                public void onFail(String s) {
                }
            });
        } catch (Exception e) {
        }

        return;
    }


    @ReactMethod
    public void closeSDkPush() {
        builder.setUserSDkPush(false);
        UdeskHttpFacade.getInstance().sdkPushStatus(appDomain, appKey, sdktoken, "off", uuid, appId, new UdeskCallBack() {
            @Override
            public void onSuccess(String s) {
            }

            @Override
            public void onFail(String s) {
            }
        });
        return;
    }

    @ReactMethod
    public void entryChat(final String imageUrl) {
        try {
            closeSDkPush();
            UdeskSDKManager.getInstance().entryChat(mReactContext.getApplicationContext(), builder.build(), this.sdktoken);

            if (imageUrl != null && imageUrl != "") {

                new Handler().postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        postImageMsg(imageUrl);
                        return;
                    }
                }, 1000);
            }
            return;
        } catch (Exception e) {

        }
        return;
    }

    @ReactMethod
    public void postImageMsg(String img) {
        if (img.startsWith("file://")) {
            img = img.substring(7, img.length());
        }
        UdeskSDKManager.getInstance().postImageMsg(mReactContext.getApplicationContext(), img);
        return;
    }


    @ReactMethod
    public void logoutUdesk() {
        UdeskSDKManager.getInstance().logoutUdesk();
        return;
    }

    @ReactMethod
    public void setBuilder() {
        builder.setUsephoto(true);
        builder.setUsecamera(true);
        builder.isShowCustomerNickname(true);
        builder.isShowCustomerHead(true);
//        builder.setUseNavigationSurvy(false);
        builder.setUdeskTitlebarBgResId(R.color.udesk_color_bg_white);


        // 返回监听
        UdeskSDKManager.getInstance().setPageBack(new PageBackCallBack() {
            @Override
            public void callBack() {
                mReactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("openWorkOrder", "");
//                UdeskSDKManager.getInstance().cleanCacheAgentId(mReactContext);
                return;
            }

            @Override
            public void callBack(String s, String s1) {

            }
        });


        //会话id回调
        UdeskSDKManager.getInstance().setSessionIdBack(new PageBackCallBack() {
            @Override
            public void callBack() {
            }

            @Override
            public void callBack(String imSubSessionId, String customerId) {
                WritableMap map = Arguments.createMap();
                map.putString("customerID", customerId);
                map.putString("imSubSessionID", imSubSessionId);

                mReactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("UdeskInfoNotification", map);
                return;
            }
        });
        return;
    }

    @ReactMethod
    public void getUnReadCount(Callback callback) {

        try {
            int num = UdeskSDKManager.getInstance().getCurrentConnectUnReadMsgCount(mReactContext.getApplicationContext(), this.sdktoken);
            callback.invoke(num);
        } catch (Exception e) {
            callback.invoke("");
        }
    }


    @ReactMethod
    public void setUserInfo(final ReadableMap options) {
        try {
            this.sdktoken = options.getString("sdk_token");

            Map<String, String> info = new HashMap<String, String>();
            info.put(UdeskConst.UdeskUserInfo.USER_SDK_TOKEN, this.sdktoken);

            //以下信息是可选
            if (hasAndNotEmpty(options, "customerToken")) {
                info.put(UdeskConst.UdeskUserInfo.CUSTOMER_TOKEN, options.getString("customerToken"));
            }
            if (hasAndNotEmpty(options, "nick_name")) {
                info.put(UdeskConst.UdeskUserInfo.NICK_NAME, options.getString("nick_name"));
            }
            if (hasAndNotEmpty(options, "email")) {
                info.put(UdeskConst.UdeskUserInfo.EMAIL, options.getString("email"));
            }
            if (hasAndNotEmpty(options, "cellphone")) {
                info.put(UdeskConst.UdeskUserInfo.CELLPHONE, options.getString("cellphone"));
            }
            if (hasAndNotEmpty(options, "description")) {
                info.put(UdeskConst.UdeskUserInfo.DESCRIPTION, options.getString("description"));
            }

            if (hasAndNotEmpty(options, "headerImage")) {
                this.builder.setCustomerUrl(options.getString("headerImage"));
            }
            if (hasAndNotEmpty(options, "uuid")) {
                this.uuid = options.getString("uuid");
            }
            // 自定义字段
            Map<String, String> _info = new HashMap<String, String>();
            if (hasAndNotEmpty(options, "companyName")) {
                _info.put(options.getString("companyName_id"), options.getString("companyName"));
            }
            if (hasAndNotEmpty(options, "enterpriseID")) {
                _info.put(options.getString("enterpriseID_id"), options.getString("enterpriseID"));
            }
            if (hasAndNotEmpty(options, "role")) {
                _info.put(options.getString("role_id"), options.getString("role"));
            }
            this.builder.setDefinedUserTextField(_info);
            // 自定义字段 end

            this.info = info;
            this.builder.setDefaultUserInfo(this.info);
            return;
        } catch (Exception e) {
        }
    }

    public static @NonNull
    boolean hasAndNotEmpty(@NonNull final ReadableMap target,
                           @NonNull final String key) {
        if (!target.hasKey(key)) {
            return false;
        }
        final String value = target.getString(key);
        return !TextUtils.isEmpty(value);
    }
}
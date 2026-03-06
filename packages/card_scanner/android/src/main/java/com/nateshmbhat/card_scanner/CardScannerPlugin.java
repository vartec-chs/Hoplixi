package com.nateshmbhat.card_scanner;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import androidx.annotation.NonNull;

import com.nateshmbhat.card_scanner.scanner_core.models.CardDetails;
import com.nateshmbhat.card_scanner.scanner_core.models.CardScannerOptions;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class CardScannerPlugin implements
        FlutterPlugin,
        MethodChannel.MethodCallHandler,
        ActivityAware,
        PluginRegistry.ActivityResultListener {

    private static final int SCAN_REQUEST_CODE = 49193;
    public static final String METHOD_CHANNEL_NAME = "nateshmbhat/card_scanner";

    private MethodChannel channel;
    private Context context;
    private Activity activity;

    private Result pendingResult;

    // ---------------------------
    // Flutter Engine
    // ---------------------------

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {

        channel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
        channel.setMethodCallHandler(this);

        context = binding.getApplicationContext();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

        channel.setMethodCallHandler(null);
        channel = null;
        context = null;
    }

    // ---------------------------
    // Activity lifecycle
    // ---------------------------

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {

        activity = binding.getActivity();

        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

        activity = binding.getActivity();

        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    // ---------------------------
    // MethodChannel
    // ---------------------------

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

        if ("scan_card".equals(call.method)) {

            if (activity == null) {
                result.error("NO_ACTIVITY", "Plugin requires foreground activity", null);
                return;
            }

            if (pendingResult != null) {
                result.error("ALREADY_ACTIVE", "Scan already running", null);
                return;
            }

            pendingResult = result;

            showCameraActivity(call);

        } else {
            result.notImplemented();
        }
    }

    // ---------------------------
    // Launch scanner activity
    // ---------------------------

    private void showCameraActivity(MethodCall call) {

        Map<String, Object> rawMap = (Map<String, Object>) call.arguments;

        Map<String, String> map = new HashMap<>();

        if (rawMap != null) {
            for (Map.Entry<String, Object> entry : rawMap.entrySet()) {
                map.put(entry.getKey(), entry.getValue().toString());
            }
        }

        CardScannerOptions options = new CardScannerOptions(map);

        Intent intent = new Intent(context, CardScannerCameraActivity.class);

        intent.putExtra(
                CardScannerCameraActivity.CARD_SCAN_OPTIONS,
                options
        );

        activity.startActivityForResult(intent, SCAN_REQUEST_CODE);
    }

    // ---------------------------
    // Result from activity
    // ---------------------------

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {

        if (requestCode != SCAN_REQUEST_CODE) return false;

        if (pendingResult == null) return false;

        if (resultCode == Activity.RESULT_OK) {

            if (data != null && data.hasExtra(CardScannerCameraActivity.SCAN_RESULT)) {

                CardDetails cardDetails =
                        data.getParcelableExtra(CardScannerCameraActivity.SCAN_RESULT);

                if (cardDetails != null) {
                    pendingResult.success(cardDetails.toMap());
                } else {
                    pendingResult.success(null);
                }

            } else {
                pendingResult.success(null);
            }

        } else {
            pendingResult.success(null);
        }

        pendingResult = null;

        return true;
    }
}

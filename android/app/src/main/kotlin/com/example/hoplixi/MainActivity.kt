package com.hoplixi.app

import io.flutter.embedding.android.FlutterFragmentActivity
import com.prongbang.screenprotect.AndroidScreenProtector

class MainActivity : FlutterFragmentActivity() {
    private val screenProtector by lazy { AndroidScreenProtector.newInstance(this) }

    override fun onPause() {
        super.onPause()
        screenProtector.protect()
    }

    override fun onResume() {
        super.onResume()
        screenProtector.unprotect()
    }

    // For Android 12+
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        screenProtector.process(hasFocus.not())
    }
}

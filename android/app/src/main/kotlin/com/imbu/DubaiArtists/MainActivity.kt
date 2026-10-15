package com.imbu.DubaiArtists

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewTreeObserver
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!isTaskRoot) {
            val intent = intent
            val action = intent.action
            if (intent.hasCategory(Intent.CATEGORY_LAUNCHER) && action != null && action == Intent.ACTION_MAIN) {
                finish()
                return
            }
        }

        // Keep native launcher screen visible for 1 second
        var isReady = false
        val content: View = findViewById(android.R.id.content)

        Handler(Looper.getMainLooper()).postDelayed({
            isReady = true
            content.invalidate()
        }, 1000)

        content.viewTreeObserver.addOnPreDrawListener(
            object : ViewTreeObserver.OnPreDrawListener {
                override fun onPreDraw(): Boolean {
                    if (isReady) {
                        content.viewTreeObserver.removeOnPreDrawListener(this)
                        return true
                    }
                    return false
                }
            }
        )
    }
}

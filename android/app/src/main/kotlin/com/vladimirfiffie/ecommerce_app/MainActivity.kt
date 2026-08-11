package com.vladimirfiffie.ecommerce_app

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * local_auth needs a FragmentActivity to host androidx BiometricPrompt —
 * with the default FlutterActivity the prompt fails at runtime.
 */
class MainActivity : FlutterFragmentActivity()

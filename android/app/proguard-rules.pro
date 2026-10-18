# PickDrop release proguard rules

# ── Flutter ──────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.plugins.** { *; }

# ── Firebase / Google Play services ──────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Google Maps ──────────────────────────────────────────────────────────
-keep class com.google.android.libraries.maps.** { *; }
-keep class com.google.maps.android.** { *; }

# ── Razorpay ─────────────────────────────────────────────────────────────
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# ── Keep annotations used by JSON serialization ──────────────────────────
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

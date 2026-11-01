# Taly native SDK: models are (de)serialized with Gson, APIs called through Retrofit
-keep class io.taly.sdk.** { *; }
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*

# Retrofit 2.9 under R8 full mode (AGP 8+)
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Gson generic types
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# @Parcelize is compile-time only; its runtime library isn't bundled with the AAR
-dontwarn kotlinx.parcelize.Parcelize
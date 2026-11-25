package io.taly.sdk_flutter

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/*
 * Run with `./gradlew :sdk_flutter:testDebugUnitTest` from `example/android/`.
 */
internal class SdkFlutterPluginTest {

    // --- clientCredentialsOf: decides between the v1.3 and the legacy initialize ---

    @Test
    fun clientCredentials_bothPresent_areUsedTrimmed() {
        assertEquals("mapi_abc" to "secret", SdkFlutterPlugin.clientCredentialsOf(" mapi_abc ", " secret "))
    }

    @Test
    fun clientCredentials_missingOrBlank_fallBackToLegacy() {
        assertNull(SdkFlutterPlugin.clientCredentialsOf(null, null))
        assertNull(SdkFlutterPlugin.clientCredentialsOf("mapi_abc", null))
        assertNull(SdkFlutterPlugin.clientCredentialsOf(null, "secret"))
        assertNull(SdkFlutterPlugin.clientCredentialsOf("", "secret"))
        assertNull(SdkFlutterPlugin.clientCredentialsOf("mapi_abc", "   "))
    }

    // --- onMethodCall: argument validation (returns before any native SDK call) ---

    @Test
    fun initialize_withoutUserName_returnsMissingParam() {
        val result = Mockito.mock(MethodChannel.Result::class.java)

        SdkFlutterPlugin().onMethodCall(
            MethodCall("initialize", mapOf("password" to "p", "clientId" to "id", "clientSecret" to "s")),
            result
        )

        Mockito.verify(result).error(Mockito.eq("MISSING_PARAM"), anyString(), isNull())
    }

    @Test
    fun initialize_withoutPassword_returnsMissingParam() {
        val result = Mockito.mock(MethodChannel.Result::class.java)

        SdkFlutterPlugin().onMethodCall(MethodCall("initialize", mapOf("userName" to "u")), result)

        Mockito.verify(result).error(Mockito.eq("MISSING_PARAM"), anyString(), isNull())
    }

    @Test
    fun unknownMethod_isNotImplemented() {
        val result = Mockito.mock(MethodChannel.Result::class.java)

        SdkFlutterPlugin().onMethodCall(MethodCall("getPlatformVersion", null), result)

        Mockito.verify(result).notImplemented()
    }
}

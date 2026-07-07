configurations.maybeCreate("default")

// ✅ This is the ONLY correct way to expose a local AAR from a sub-module
artifacts.add("default", file("libs/taly-sdk-release.aar"))
# ML Kit and WorkManager create these classes by reflection. R8 removes their
# constructors in release builds, and the app crashes at startup.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
-keep class * extends androidx.room.RoomDatabase { <init>(); }

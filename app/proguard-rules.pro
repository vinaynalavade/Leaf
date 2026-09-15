# Proguard rules for Expense Tracker

# Room SQLite
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.room.paging.**

# DataStore & Protobuf
-keepclassmembers class * extends androidx.datastore.core.Serializer {
    <fields>;
    <methods>;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Leaf Entities, DAOs & Backup Models
-keep class com.vinaynalavade.expensetracker.data.local.entity.** { *; }
-keep class com.vinaynalavade.expensetracker.data.local.dao.** { *; }
-keep class com.vinaynalavade.expensetracker.core.backup.** { *; }
-keep class com.vinaynalavade.expensetracker.core.model.** { *; }
-keep class com.vinaynalavade.expensetracker.core.split.** { *; }
-keep class com.vinaynalavade.expensetracker.core.calculator.** { *; }
-keep class com.vinaynalavade.expensetracker.domain.model.** { *; }
-keep class com.vinaynalavade.expensetracker.presentation.navigation.Screen** { *; }
-keep class com.vinaynalavade.expensetracker.presentation.widget.model.** { *; }
-keep class com.vinaynalavade.expensetracker.presentation.**ViewModel { *; }
-keepclassmembers class com.vinaynalavade.expensetracker.presentation.**ViewModel { *; }


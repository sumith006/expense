// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final typeId = 14;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      currencySymbol: fields[0] as String,
      themeModeIndex: (fields[1] as num).toInt(),
      isPinEnabled: fields[2] as bool,
      isBiometricEnabled: fields[3] as bool,
      dailyReminderEnabled: fields[4] as bool,
      dailyReminderHour: (fields[5] as num?)?.toInt(),
      dailyReminderMinute: (fields[6] as num?)?.toInt(),
      taskReminderEnabled: fields[7] as bool,
      taskReminderMinutesBefore: (fields[8] as num).toInt(),
      profileName: fields[9] as String?,
      profileAvatarPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.currencySymbol)
      ..writeByte(1)
      ..write(obj.themeModeIndex)
      ..writeByte(2)
      ..write(obj.isPinEnabled)
      ..writeByte(3)
      ..write(obj.isBiometricEnabled)
      ..writeByte(4)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(5)
      ..write(obj.dailyReminderHour)
      ..writeByte(6)
      ..write(obj.dailyReminderMinute)
      ..writeByte(7)
      ..write(obj.taskReminderEnabled)
      ..writeByte(8)
      ..write(obj.taskReminderMinutesBefore)
      ..writeByte(9)
      ..write(obj.profileName)
      ..writeByte(10)
      ..write(obj.profileAvatarPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

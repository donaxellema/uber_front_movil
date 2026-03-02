import 'package:flutter_bloc/flutter_bloc.dart';

enum AppMode { passenger, driver }

class AppModeCubit extends Cubit<AppMode> {
  AppModeCubit() : super(AppMode.passenger);

  void toggleMode() {
    if (state == AppMode.passenger) {
      emit(AppMode.driver);
    } else {
      emit(AppMode.passenger);
    }
  }

  void setMode(AppMode mode) {
    emit(mode);
  }

  bool get isDriverMode => state == AppMode.driver;
  bool get isPassengerMode => state == AppMode.passenger;
}

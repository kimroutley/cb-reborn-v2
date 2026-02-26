import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'host_destinations.dart';

class HostNavigationNotifier extends Notifier<HostDestination> {
  @override
  HostDestination build() => HostDestination.home;

  void setDestination(HostDestination destination) {
    state = destination;
  }
}

final hostNavigationProvider =
    NotifierProvider<HostNavigationNotifier, HostDestination>(() {
      return HostNavigationNotifier();
    });

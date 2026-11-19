/// BR-03: every service takes 120–180 minutes.
const minDuration = 120, maxDuration = 180;

const serviceTypes = ['Gel', 'Extensions', 'Nail art'];

class Service {
  const Service({
    required this.serviceId,
    required this.name,
    required this.serviceType,
    required this.priceRm,
    required this.durationMax,
    this.isActive = true,
  });

  final String serviceId, name, serviceType;
  final double priceRm;

  /// Minutes.
  final int durationMax;
  final bool isActive;

  Service copyWith({
    String? name,
    String? serviceType,
    double? priceRm,
    int? durationMax,
    bool? isActive,
  }) => Service(
    serviceId: serviceId,
    name: name ?? this.name,
    serviceType: serviceType ?? this.serviceType,
    priceRm: priceRm ?? this.priceRm,
    durationMax: durationMax ?? this.durationMax,
    isActive: isActive ?? this.isActive,
  );
}

class Design {
  const Design({
    required this.designId,
    required this.serviceId,
    required this.title,
    required this.imageUrl,
  });

  final String designId, serviceId, title, imageUrl;
}

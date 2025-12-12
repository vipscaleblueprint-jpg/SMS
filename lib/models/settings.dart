class Settings {
  final SimSelection simStrategy;

  const Settings({this.simStrategy = SimSelection.sim1});

  Settings copyWith({SimSelection? simStrategy}) {
    return Settings(simStrategy: simStrategy ?? this.simStrategy);
  }

  Map<String, dynamic> toJson() {
    return {'sim_strategy': simStrategy.name};
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      simStrategy: SimSelection.values.firstWhere(
        (e) => e.name == json['sim_strategy'],
        orElse: () => SimSelection.sim1,
      ),
    );
  }
}

enum SimSelection { sim1, sim2, all }

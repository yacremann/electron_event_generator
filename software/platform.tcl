platform create -name DldSimulatorPlatform -hw electron_event_generator.xsa -out  ./ -os standalone -proc microblaze_0
platform active {DldSimulatorPlatform}
platform clean
platform generate

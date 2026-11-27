// Militech "Hope" Sandevistan — hooks into the vanilla Sandevistan state machine.
module MilitechHope

@wrapMethod(SandevistanEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) {
    let owner = scriptInterface.executionOwner;
    let system: ref<MilitechHopeSystem>;
    let overheat = false;

    if IsDefined(owner) && owner.IsPlayer() {
        system = MilitechHopeSystem.Get(scriptInterface.GetGame());
        if IsDefined(system) {
            overheat = system.OnSandevistanEnter(owner);
        }
    }

    wrappedMethod(stateContext, scriptInterface);

    if overheat {
        system.TriggerOverheat(owner);
    }
}

@wrapMethod(SandevistanEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) {
    wrappedMethod(stateContext, scriptInterface);

    let owner = scriptInterface.executionOwner;
    if IsDefined(owner) && owner.IsPlayer() {
        let system = MilitechHopeSystem.Get(scriptInterface.GetGame());
        if IsDefined(system) {
            system.OnSandevistanExit(owner);
        }
    }
}

@wrapMethod(SandevistanEvents)
protected final func OnForcedExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) {
    wrappedMethod(stateContext, scriptInterface);

    let owner = scriptInterface.executionOwner;
    if IsDefined(owner) && owner.IsPlayer() {
        let system = MilitechHopeSystem.Get(scriptInterface.GetGame());
        if IsDefined(system) {
            system.OnSandevistanExit(owner);
        }
    }
}

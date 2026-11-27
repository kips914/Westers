// Militech "Hope" Sandevistan — hooks outside the Sandevistan state machine:
//   * player kills   -> quick recharge upgrade, Axolotl cooling, broker contracts
//   * loot containers -> the broker's business card can turn up inside
module MilitechHope

@wrapMethod(PlayerPuppet)
protected cb func OnTargetNeutraliziedEvent(evt: ref<TargetNeutraliziedEvent>) -> Bool {
    let result = wrappedMethod(evt);
    if IsDefined(evt) && (Equals(evt.type, ENeutralizeType.Killed) || Equals(evt.type, ENeutralizeType.Defeated)) {
        let system = MilitechHopeSystem.Get(this.GetGame());
        if IsDefined(system) {
            system.OnPlayerKill(this, evt.targetID);
        }
    }
    return result;
}

@wrapMethod(gameContainerObjectBase)
protected cb func OnInteractionActivated(evt: ref<InteractionActivationEvent>) -> Bool {
    let result = wrappedMethod(evt);
    if IsDefined(evt) && Equals(evt.eventType, gameinteractionsEInteractionEventType.EIET_activate)
        && IsDefined(evt.activator) && evt.activator.IsPlayer() {
        let system = MilitechHopeSystem.Get(this.GetGame());
        if IsDefined(system) {
            system.OnContainerApproached(this);
        }
    }
    return result;
}

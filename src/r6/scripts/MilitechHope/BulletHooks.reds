// Militech "Hope" Sandevistan, Tier 5++ perk "Last Hope protocol".
//
// Vanilla: while any time dilation is active, the player's non-Tech guns
// switch to the *TimeDilated attack records, i.e. slow visible projectiles.
// With a Tier 5++ Hope running we hand back the regular attack records
// instead, so bullets keep their normal speed and hit instantly.
module MilitechHope

@wrapMethod(WeaponTransition)
protected func GetDesiredAttackRecord(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> ref<Attack_Record> {
    let vanilla = wrappedMethod(stateContext, scriptInterface);

    let owner = scriptInterface.executionOwner;
    if !IsDefined(owner) || !owner.IsPlayer() {
        return vanilla;
    }
    if !scriptInterface.GetTimeSystem().IsTimeDilationActive(TimeDilationHelper.GetSandevistanKey()) {
        return vanilla;
    }
    let system = MilitechHopeSystem.Get(scriptInterface.GetGame());
    if !IsDefined(system) || !system.HasRealSpeedBullets() {
        return vanilla;
    }

    // m_rangedAttackPackage was refreshed by the vanilla call above.
    let package = this.m_rangedAttackPackage;
    if !IsDefined(package) {
        return vanilla;
    }
    let weapon = scriptInterface.owner as WeaponObject;
    let rangedAttack: wref<RangedAttack_Record> = package.DefaultFire();
    if IsDefined(weapon) && WeaponObject.GetWeaponChargeNormalized(weapon) >= 1.0 {
        rangedAttack = package.ChargeFire();
    }
    if !IsDefined(rangedAttack) {
        return vanilla;
    }

    let attack: wref<Attack_Record>;
    let isAiming = scriptInterface.localBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody) == Cast<Int32>(EnumInt(gamePSMUpperBodyStates.Aim));
    if isAiming {
        attack = rangedAttack.SecondaryPlayerAttack();
    }
    if !IsDefined(attack) {
        attack = rangedAttack.PlayerAttack();
    }
    if !IsDefined(attack) {
        return vanilla;
    }
    return attack;
}

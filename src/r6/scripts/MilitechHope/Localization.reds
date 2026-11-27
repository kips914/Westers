// Militech "Hope" Sandevistan — texts (Codeware localization).
// Russian for ru-ru, English for every other language.
module MilitechHope.Localization
import Codeware.Localization.*

public class HopeLocalizationProvider extends ModLocalizationProvider {
    public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
        if Equals(language, n"ru-ru") {
            return new HopeRussian();
        }
        return new HopeEnglish();
    }

    public func GetFallback() -> CName {
        return n"en-us";
    }
}

public class HopeRussian extends ModLocalizationPackage {
    protected func DefineTexts() -> Void {
        this.Text("MilitechHope-Name", "Сандевистан Militech «Надежда»");
        this.Text("MilitechHope-Lore", "Militech MK-0 «Надежда» — экспериментальный нейроускоритель для спецподразделений NUSA. По документам вся партия сгорела при перевозке через порт Арасаки. По факту — один экземпляр уцелел. Он разгоняет нервную систему так, что мир почти замирает, но систему охлаждения так и не довели до ума: «Надежда» не прощает, когда её гоняют без передышки.");
        this.Text("MilitechHope-Core-T5", "НЕЙРОУСКОРЕНИЕ — время замедляется на 95% на 5 сек. Полная перезарядка — 10 сек. Можно включить снова, не дожидаясь полного заряда. Убийства во время замедления возвращают 10% заряда.");
        this.Text("MilitechHope-Core-T5P", "НЕЙРОУСКОРЕНИЕ — время замедляется на 97% на 7,5 сек. Полная перезарядка — 10 сек. Можно включить снова, не дожидаясь полного заряда. Убийства во время замедления возвращают 10% заряда.");
        this.Text("MilitechHope-Core-T5PP", "НЕЙРОУСКОРЕНИЕ — время замедляется на 99% на 10 сек. Полная перезарядка — 10 сек. Можно включить снова, не дожидаясь полного заряда. Убийства во время замедления возвращают 10% заряда.");
        this.Text("MilitechHope-Passive-T5", "БОЕВАЯ ПРОШИВКА — постоянно: +10% к урону критических попаданий, +5% к шансу крит. попадания, +12 к выносливости.");
        this.Text("MilitechHope-Passive-T5P", "БОЕВАЯ ПРОШИВКА — постоянно: +10% к урону критических попаданий, +7% к шансу крит. попадания, +12 к выносливости.");
        this.Text("MilitechHope-Passive-T5PP", "БОЕВАЯ ПРОШИВКА — постоянно: +10% к урону критических попаданий, +10% к шансу крит. попадания, +12 к выносливости.");
        this.Text("MilitechHope-Active-T5", "ПРОТОКОЛ «ОХОТНИК» — пока активен Сандевистан: +15% к урону в голову, +10% к шансу смягчения урона, +50 к броне.");
        this.Text("MilitechHope-Active-T5P", "ПРОТОКОЛ «ОХОТНИК» — пока активен Сандевистан: +20% к урону в голову, +15% к шансу смягчения урона, +70 к броне.");
        this.Text("MilitechHope-Active-T5PP", "ПРОТОКОЛ «ОХОТНИК» — пока активен Сандевистан: +25% к урону в голову, +20% к шансу смягчения урона, +90 к броне.");
        this.Text("MilitechHope-Kill-T5", "АДРЕНАЛИНОВЫЙ КОНТУР — каждое убийство под Сандевистаном восстанавливает 20% выносливости.");
        this.Text("MilitechHope-Kill-T5P", "АДРЕНАЛИНОВЫЙ КОНТУР — каждое убийство под Сандевистаном восстанавливает 20% выносливости и 5% здоровья.");
        this.Text("MilitechHope-Kill-T5PP", "АДРЕНАЛИНОВЫЙ КОНТУР — каждое убийство под Сандевистаном восстанавливает 25% выносливости и 8% здоровья.");
        this.Text("MilitechHope-Bullets", "ПРОТОКОЛ «ПОСЛЕДНЯЯ НАДЕЖДА» (макс. уровень) — пули из вашего огнестрельного оружия не замедляются: во время Сандевистана они летят с обычной скоростью и попадают в цель мгновенно.");
        this.Text("MilitechHope-Overheat-T5", "ИЗЪЯН: ПЕРЕГРЕВ — каждая активация нагревает ядро на 22 °C (в покое 40 °C). При 120 °C имплант отключается и 12 сек. принудительно перезаряжается: обычно это 4-я активация подряд. Активация с полного заряда греет вдвое меньше, а полностью перезаряженная «Надежда» остывает до 40 °C.");
        this.Text("MilitechHope-Overheat-T5PP", "ИЗЪЯН: ПЕРЕГРЕВ — каждая активация нагревает ядро на 30 °C (в покое 40 °C). При 120 °C имплант отключается и 12 сек. принудительно перезаряжается: обычно это 3-я активация подряд. Активация с полного заряда греет вдвое меньше, а полностью перезаряженная «Надежда» остывает до 40 °C.");
        this.Text("MilitechHope-Msg-OverheatWarning", "«НАДЕЖДА»: температура ядра критическая —");
        this.Text("MilitechHope-Msg-Overheat", "«НАДЕЖДА»: ОШИБКА ПЕРЕГРЕВА. Принудительная перезарядка.");
        this.Text("MilitechHope-Msg-LevelLocked", "Входящее сообщение зашифровано. Нужен уровень 40, чтобы его прочитать.");
        this.Text("MilitechHope-Msg-Sms", "Новое сообщение [неизвестный номер]: «Видел тебя на набережной. Контейнер Militech, который «потерялся» в порту, теперь у колумбария на кладбище. Метку я поставил. Забирай, пока NUSA не спохватились».");
        this.Text("MilitechHope-Msg-Complete", "Получено: Сандевистан Militech «Надежда». Задание «Надежда» выполнено.");
        this.Text("MilitechHope-UpgradeSlot", "СЛОТ УЛУЧШЕНИЯ (макс. уровень) — в «Надежду» можно установить один модуль Militech: Разряд, Быстрая перезарядка, Новое дыхание, Фазовый щит, Берсерк или Настоящее безумие.");
        this.Text("MilitechHope-Mod-Lore", "Модуль прошивки Militech для Сандевистана «Надежда» 5++. Устанавливается в слот улучшения импланта. В реестрах Militech не значится.");
        this.Text("MilitechHope-Mod-Discharge-Name", "Модуль «Разряд»");
        this.Text("MilitechHope-Mod-Discharge-Desc", "РАЗРЯД — когда Сандевистан отключается во время боя, остаток заряда бьёт током всех врагов в радиусе 2 м.");
        this.Text("MilitechHope-Mod-QuickCharge-Name", "Модуль «Быстрая перезарядка»");
        this.Text("MilitechHope-Mod-QuickCharge-Desc", "БЫСТРАЯ ПЕРЕЗАРЯДКА — 5 убийств за 15 сек. мгновенно заряжают Сандевистан на 100%.");
        this.Text("MilitechHope-Mod-NewBreath-Name", "Модуль «Новое дыхание»");
        this.Text("MilitechHope-Mod-NewBreath-Desc", "НОВОЕ ДЫХАНИЕ — если здоровье ниже 40%, Сандевистан работает 15 сек. (с рефлекторным модулятором — ниже 50%).");
        this.Text("MilitechHope-Mod-PhaseShield-Name", "Модуль «Фазовый щит»");
        this.Text("MilitechHope-Mod-PhaseShield-Desc", "ФАЗОВЫЙ ЩИТ — первые 1,5 сек. после включения Сандевистана вы не получаете урона.");
        this.Text("MilitechHope-Mod-Berserk-Name", "Модуль «Берсерк»");
        this.Text("MilitechHope-Mod-Berserk-Desc", "БЕРСЕРК — под Сандевистаном пули летят с обычной скоростью, +30% к скорости бега, +15% к урону, +5% к шансу крит. попадания. Цена: выносливость сгорает очень быстро, а после каждой активации наступает перегрев.");
        this.Text("MilitechHope-Mod-TrueMadness-Name", "Модуль «Настоящее безумие»");
        this.Text("MilitechHope-Mod-TrueMadness-Desc", "НАСТОЯЩЕЕ БЕЗУМИЕ — с шансом 25% при активации время останавливается полностью на 5 сек. Цена: ядро нагревается ещё на 45 °C, а выносливость быстро сгорает.");
        this.Text("MilitechHope-Card-Name", "Визитка: «М. — поставки Militech»");
        this.Text("MilitechHope-Card-Desc", "Чёрная визитка с логотипом Militech и номером без имени. На обороте от руки: «Железо для Надежды. Звони». Нажмите F7, чтобы позвонить.");
        this.Text("MilitechHope-Msg-CardNearby", "В этом контейнере что-то блеснуло: визитка с логотипом Militech.");
        this.Text("MilitechHope-Msg-CardSms", "Новый контакт: «М. — поставки Militech». Нажмите F7, чтобы позвонить: магазин модулей «Надежды» и контракты.");
        this.Text("MilitechHope-Msg-ContractDone", "Контракт Militech выполнен. Позвоните М. (F7), чтобы забрать награду.");
        this.Text("MilitechHope-Msg-Discharge", "«НАДЕЖДА»: разряд, поражено целей:");
        this.Text("MilitechHope-Msg-QuickCharge", "«НАДЕЖДА»: серия убийств, заряд 100%.");
        this.Text("MilitechHope-Msg-NewBreath", "«НАДЕЖДА»: НОВОЕ ДЫХАНИЕ — 15 сек.");
        this.Text("MilitechHope-Msg-Berserk", "«НАДЕЖДА»: БЕРСЕРК. После отключения будет перегрев.");
        this.Text("MilitechHope-Msg-Madness", "«НАДЕЖДА»: НАСТОЯЩЕЕ БЕЗУМИЕ. Время остановлено.");
        this.Text("MilitechHope-Hud-Title", "«НАДЕЖДА» · ТЕМПЕРАТУРА ЯДРА");
        this.Text("MilitechHope-Hud-Active", "АКТИВНА");
        this.Text("MilitechHope-Hud-Overheat", "ПЕРЕГРЕВ · ПРИНУДИТЕЛЬНАЯ ПЕРЕЗАРЯДКА");
        this.Text("MilitechHope-Hud-Critical", "КРИТИЧЕСКАЯ ТЕМПЕРАТУРА");
        this.Text("MilitechHope-Hud-Ready", "ГОТОВА");
        this.Text("MilitechHope-Hud-Cooling", "ОХЛАЖДЕНИЕ");
        this.Text("MilitechHope-Hud-Charge", "заряд");
        this.Text("MilitechHope-Hud-Madness", "БЕЗУМИЕ");
        this.Text("MilitechHope-Hud-Phase", "ЩИТ");
        this.Text("MilitechHope-Hud-Berserk", "БЕРСЕРК");
        this.Text("MilitechHope-Hud-Module", "Модуль:");
        this.Text("MilitechHope-Hud-Sync", "Синхронизация:");
        this.Text("MilitechHope-Implant-Axolotl", "Аксолотль");
        this.Text("MilitechHope-Implant-Cox2", "Кокс-2");
        this.Text("MilitechHope-Implant-Bioconductor", "Биопроводники");
        this.Text("MilitechHope-Implant-Adrenaline", "Адреналиновый ускоритель");
        this.Text("MilitechHope-Implant-SecondHeart", "Второе сердце");
        this.Text("MilitechHope-Implant-ReflexTuner", "Рефлекторный модулятор");
        this.Text("MilitechHope-Broker-Title", "M. · ПОСТАВКИ MILITECH · ЗАЩИЩЁННЫЙ КАНАЛ");
        this.Text("MilitechHope-Broker-Greeting", "«Слушаю. Только быстро.»");
        this.Text("MilitechHope-Broker-Sandevistan", "Сандевистан Militech «Надежда»");
        this.Text("MilitechHope-Broker-Owned", "есть:");
        this.Text("MilitechHope-Broker-Installed", "установлен");
        this.Text("MilitechHope-Broker-ContractNew", "Взять контракт, награда:");
        this.Text("MilitechHope-Broker-ContractActive", "Контракт: убийства под «Надеждой»");
        this.Text("MilitechHope-Broker-ContractReady", "Забрать награду за контракт:");
        this.Text("MilitechHope-Broker-ContractNone", "Контрактов больше нет");
        this.Text("MilitechHope-Broker-ContractTaken", "Контракт принят. Убийств под «Надеждой» нужно:");
        this.Text("MilitechHope-Broker-ContractReward", "Награда получена:");
        this.Text("MilitechHope-Broker-Install", "Установить модуль в «Надежду» 5++ (по кругу)");
        this.Text("MilitechHope-Broker-HangUp", "Положить трубку");
        this.Text("MilitechHope-Broker-Balance", "Баланс:");
        this.Text("MilitechHope-Broker-NoMoney", "«Не хватает эдди. Приходи, когда будут.»");
        this.Text("MilitechHope-Broker-Bought", "Куплено:");
        this.Text("MilitechHope-Broker-InstalledOk", "Установлено:");
        this.Text("MilitechHope-Broker-NeedT5PP", "Нужна установленная «Надежда» 5++.");
        this.Text("MilitechHope-Broker-NoUpgrades", "Нет модулей для установки.");
        this.Text("MilitechHope-Broker-InstallFailed", "Не удалось установить модуль.");
        this.Text("MilitechHope-Broker-Hint", "Стрелки вверх/вниз — выбор   Enter — подтвердить   Backspace или F7 — положить трубку");
    }
}

public class HopeEnglish extends ModLocalizationPackage {
    protected func DefineTexts() -> Void {
        this.Text("MilitechHope-Name", "Militech \"Hope\" Sandevistan");
        this.Text("MilitechHope-Lore", "Militech MK-0 \"Hope\" is an experimental neural accelerator built for NUSA special forces. On paper, the whole batch burned up while passing through the Arasaka port. In reality, one unit survived. It pushes your nervous system so hard the world all but stops, but the cooling system was never finished: Hope does not forgive being pushed without a break.");
        this.Text("MilitechHope-Core-T5", "NEURAL BOOST: slows time by 95% for 5 sec. Full recharge takes 10 sec. Can be reactivated before it is fully charged. Kills during the slowdown restore 10% charge.");
        this.Text("MilitechHope-Core-T5P", "NEURAL BOOST: slows time by 97% for 7.5 sec. Full recharge takes 10 sec. Can be reactivated before it is fully charged. Kills during the slowdown restore 10% charge.");
        this.Text("MilitechHope-Core-T5PP", "NEURAL BOOST: slows time by 99% for 10 sec. Full recharge takes 10 sec. Can be reactivated before it is fully charged. Kills during the slowdown restore 10% charge.");
        this.Text("MilitechHope-Passive-T5", "COMBAT FIRMWARE, always on: +10% Crit Damage, +5% Crit Chance, +12 Stamina.");
        this.Text("MilitechHope-Passive-T5P", "COMBAT FIRMWARE, always on: +10% Crit Damage, +7% Crit Chance, +12 Stamina.");
        this.Text("MilitechHope-Passive-T5PP", "COMBAT FIRMWARE, always on: +10% Crit Damage, +10% Crit Chance, +12 Stamina.");
        this.Text("MilitechHope-Active-T5", "HUNTER PROTOCOL, while Sandevistan is active: +15% Headshot Damage, +10% Mitigation Chance, +50 Armor.");
        this.Text("MilitechHope-Active-T5P", "HUNTER PROTOCOL, while Sandevistan is active: +20% Headshot Damage, +15% Mitigation Chance, +70 Armor.");
        this.Text("MilitechHope-Active-T5PP", "HUNTER PROTOCOL, while Sandevistan is active: +25% Headshot Damage, +20% Mitigation Chance, +90 Armor.");
        this.Text("MilitechHope-Kill-T5", "ADRENALINE LOOP: every kill under Sandevistan restores 20% Stamina.");
        this.Text("MilitechHope-Kill-T5P", "ADRENALINE LOOP: every kill under Sandevistan restores 20% Stamina and 5% Health.");
        this.Text("MilitechHope-Kill-T5PP", "ADRENALINE LOOP: every kill under Sandevistan restores 25% Stamina and 8% Health.");
        this.Text("MilitechHope-Bullets", "LAST HOPE PROTOCOL (max level): your firearm bullets are not slowed. During Sandevistan they fly at their normal speed and hit instantly.");
        this.Text("MilitechHope-Overheat-T5", "FLAW, OVERHEAT: every activation heats the core by 22 °C (40 °C at rest). At 120 °C the implant shuts down and is forced into a 12 sec recharge, usually on the 4th activation in a row. Activating from a full charge heats half as much, and a fully recharged Hope cools back to 40 °C.");
        this.Text("MilitechHope-Overheat-T5PP", "FLAW, OVERHEAT: every activation heats the core by 30 °C (40 °C at rest). At 120 °C the implant shuts down and is forced into a 12 sec recharge, usually on the 3rd activation in a row. Activating from a full charge heats half as much, and a fully recharged Hope cools back to 40 °C.");
        this.Text("MilitechHope-Msg-OverheatWarning", "HOPE: critical core temperature,");
        this.Text("MilitechHope-Msg-Overheat", "HOPE: OVERHEAT ERROR. Forced recharge.");
        this.Text("MilitechHope-Msg-LevelLocked", "Incoming message is encrypted. You need level 40 to read it.");
        this.Text("MilitechHope-Msg-Sms", "New message [unknown number]: \"Saw you at the waterfront. The Militech case that got 'lost' at the port is now by the Columbarium at the cemetery. I marked it for you. Grab it before NUSA notices.\"");
        this.Text("MilitechHope-Msg-Complete", "Received: Militech \"Hope\" Sandevistan. Job \"Hope\" complete.");
        this.Text("MilitechHope-UpgradeSlot", "UPGRADE SLOT (max level): Hope accepts one Militech module: Discharge, Quick Recharge, New Breath, Phase Shield, Berserk or True Madness.");
        this.Text("MilitechHope-Mod-Lore", "Militech firmware module for the Hope 5++ Sandevistan. Goes into the implant's upgrade slot. Not listed in any Militech registry.");
        this.Text("MilitechHope-Mod-Discharge-Name", "Discharge Module");
        this.Text("MilitechHope-Mod-Discharge-Desc", "DISCHARGE: when Sandevistan ends during combat, the leftover charge shocks every enemy within 2 m.");
        this.Text("MilitechHope-Mod-QuickCharge-Name", "Quick Recharge Module");
        this.Text("MilitechHope-Mod-QuickCharge-Desc", "QUICK RECHARGE: 5 kills within 15 sec instantly refill Sandevistan to 100%.");
        this.Text("MilitechHope-Mod-NewBreath-Name", "New Breath Module");
        this.Text("MilitechHope-Mod-NewBreath-Desc", "NEW BREATH: below 40% Health, Sandevistan lasts 15 sec (below 50% with a Reflex Tuner).");
        this.Text("MilitechHope-Mod-PhaseShield-Name", "Phase Shield Module");
        this.Text("MilitechHope-Mod-PhaseShield-Desc", "PHASE SHIELD: you take no damage for the first 1.5 sec after Sandevistan activates.");
        this.Text("MilitechHope-Mod-Berserk-Name", "Berserk Module");
        this.Text("MilitechHope-Mod-Berserk-Desc", "BERSERK: during Sandevistan bullets fly at normal speed, +30% movement speed, +15% damage, +5% Crit Chance. Cost: Stamina burns very fast, and every activation ends in an overheat.");
        this.Text("MilitechHope-Mod-TrueMadness-Name", "True Madness Module");
        this.Text("MilitechHope-Mod-TrueMadness-Desc", "TRUE MADNESS: 25% chance on activation to stop time completely for 5 sec. Cost: the core heats up by another 45 °C and Stamina burns fast.");
        this.Text("MilitechHope-Card-Name", "Business card: \"M. - Militech supply\"");
        this.Text("MilitechHope-Card-Desc", "A black card with the Militech logo and a number with no name. Handwritten on the back: \"Hardware for Hope. Call me.\" Press F7 to call.");
        this.Text("MilitechHope-Msg-CardNearby", "Something glints in this container: a card with the Militech logo.");
        this.Text("MilitechHope-Msg-CardSms", "New contact: \"M. - Militech supply\". Press F7 to call: Hope module shop and contracts.");
        this.Text("MilitechHope-Msg-ContractDone", "Militech contract complete. Call M. (F7) to collect your reward.");
        this.Text("MilitechHope-Msg-Discharge", "HOPE: discharge, targets hit:");
        this.Text("MilitechHope-Msg-QuickCharge", "HOPE: kill streak, charge 100%.");
        this.Text("MilitechHope-Msg-NewBreath", "HOPE: NEW BREATH, 15 sec.");
        this.Text("MilitechHope-Msg-Berserk", "HOPE: BERSERK. It will overheat when it ends.");
        this.Text("MilitechHope-Msg-Madness", "HOPE: TRUE MADNESS. Time stopped.");
        this.Text("MilitechHope-Hud-Title", "HOPE · CORE TEMPERATURE");
        this.Text("MilitechHope-Hud-Active", "ACTIVE");
        this.Text("MilitechHope-Hud-Overheat", "OVERHEAT · FORCED RECHARGE");
        this.Text("MilitechHope-Hud-Critical", "CRITICAL TEMPERATURE");
        this.Text("MilitechHope-Hud-Ready", "READY");
        this.Text("MilitechHope-Hud-Cooling", "COOLING");
        this.Text("MilitechHope-Hud-Charge", "charge");
        this.Text("MilitechHope-Hud-Madness", "MADNESS");
        this.Text("MilitechHope-Hud-Phase", "SHIELD");
        this.Text("MilitechHope-Hud-Berserk", "BERSERK");
        this.Text("MilitechHope-Hud-Module", "Module:");
        this.Text("MilitechHope-Hud-Sync", "Synced:");
        this.Text("MilitechHope-Implant-Axolotl", "Axolotl");
        this.Text("MilitechHope-Implant-Cox2", "Cox-2");
        this.Text("MilitechHope-Implant-Bioconductor", "Bioconductor");
        this.Text("MilitechHope-Implant-Adrenaline", "Adrenaline Booster");
        this.Text("MilitechHope-Implant-SecondHeart", "Second Heart");
        this.Text("MilitechHope-Implant-ReflexTuner", "Reflex Tuner");
        this.Text("MilitechHope-Broker-Title", "M. · MILITECH SUPPLY · SECURE LINE");
        this.Text("MilitechHope-Broker-Greeting", "\"Talk. Make it quick.\"");
        this.Text("MilitechHope-Broker-Sandevistan", "Militech \"Hope\" Sandevistan");
        this.Text("MilitechHope-Broker-Owned", "owned:");
        this.Text("MilitechHope-Broker-Installed", "installed");
        this.Text("MilitechHope-Broker-ContractNew", "Take a contract, reward:");
        this.Text("MilitechHope-Broker-ContractActive", "Contract: kills under Hope");
        this.Text("MilitechHope-Broker-ContractReady", "Collect contract reward:");
        this.Text("MilitechHope-Broker-ContractNone", "No more contracts");
        this.Text("MilitechHope-Broker-ContractTaken", "Contract accepted. Kills under Hope needed:");
        this.Text("MilitechHope-Broker-ContractReward", "Reward received:");
        this.Text("MilitechHope-Broker-Install", "Install a module into Hope 5++ (cycles)");
        this.Text("MilitechHope-Broker-HangUp", "Hang up");
        this.Text("MilitechHope-Broker-Balance", "Balance:");
        this.Text("MilitechHope-Broker-NoMoney", "\"Not enough eddies. Come back when you have them.\"");
        this.Text("MilitechHope-Broker-Bought", "Bought:");
        this.Text("MilitechHope-Broker-InstalledOk", "Installed:");
        this.Text("MilitechHope-Broker-NeedT5PP", "You need Hope 5++ equipped.");
        this.Text("MilitechHope-Broker-NoUpgrades", "No modules to install.");
        this.Text("MilitechHope-Broker-InstallFailed", "Could not install the module.");
        this.Text("MilitechHope-Broker-Hint", "Arrows Up/Down: select   Enter: confirm   Backspace or F7: hang up");
    }
}

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
        this.Text("MilitechHope-Overheat-T5", "ИЗЪЯН: ПЕРЕГРЕВ — больше 3 активаций подряд вызывают ошибку охлаждения. Имплант принудительно отключается и перезаряжается 12 сек.");
        this.Text("MilitechHope-Overheat-T5PP", "ИЗЪЯН: ПЕРЕГРЕВ — больше 2 активаций подряд вызывают ошибку охлаждения. Имплант принудительно отключается и перезаряжается 12 сек.");
        this.Text("MilitechHope-Msg-OverheatWarning", "«НАДЕЖДА»: температура критическая. Следующая активация вызовет перегрев.");
        this.Text("MilitechHope-Msg-Overheat", "«НАДЕЖДА»: ОШИБКА ПЕРЕГРЕВА. Принудительная перезарядка 12 сек.");
        this.Text("MilitechHope-Msg-LevelLocked", "Входящее сообщение зашифровано. Нужен уровень 40, чтобы его прочитать.");
        this.Text("MilitechHope-Msg-Sms", "Новое сообщение [неизвестный номер]: «Видел тебя на набережной. Контейнер Militech, который «потерялся» в порту, теперь у колумбария на кладбище. Метку я поставил. Забирай, пока NUSA не спохватились».");
        this.Text("MilitechHope-Msg-Complete", "Получено: Сандевистан Militech «Надежда». Задание «Надежда» выполнено.");
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
        this.Text("MilitechHope-Overheat-T5", "FLAW, OVERHEAT: more than 3 activations in a row cause a cooling error. The implant shuts down and is forced into a 12 sec recharge.");
        this.Text("MilitechHope-Overheat-T5PP", "FLAW, OVERHEAT: more than 2 activations in a row cause a cooling error. The implant shuts down and is forced into a 12 sec recharge.");
        this.Text("MilitechHope-Msg-OverheatWarning", "HOPE: critical temperature. The next activation will overheat the implant.");
        this.Text("MilitechHope-Msg-Overheat", "HOPE: OVERHEAT ERROR. Forced recharge for 12 sec.");
        this.Text("MilitechHope-Msg-LevelLocked", "Incoming message is encrypted. You need level 40 to read it.");
        this.Text("MilitechHope-Msg-Sms", "New message [unknown number]: \"Saw you at the waterfront. The Militech case that got 'lost' at the port is now by the Columbarium at the cemetery. I marked it for you. Grab it before NUSA notices.\"");
        this.Text("MilitechHope-Msg-Complete", "Received: Militech \"Hope\" Sandevistan. Job \"Hope\" complete.");
    }
}

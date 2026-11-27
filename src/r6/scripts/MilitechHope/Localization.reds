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
        this.Text("MilitechHope-Lore", "Экспериментальный военный образец Militech для спецподразделений NUSA. Партия числилась уничтоженной при перевозке через порт Арасаки. Систему охлаждения так и не довели до ума — «Надежда» не любит, когда её гоняют без передышки.");
        this.Text("MilitechHope-Stats-T5", "Замедляет время на 95% на 5 сек. Заряд полностью восстанавливается за 10 сек. Можно активировать повторно, не дожидаясь полной перезарядки.");
        this.Text("MilitechHope-Stats-T5P", "Замедляет время на 97% на 7,5 сек. Заряд полностью восстанавливается за 10 сек. Можно активировать повторно, не дожидаясь полной перезарядки.");
        this.Text("MilitechHope-Stats-T5PP", "Замедляет время на 99% на 10 сек. Заряд полностью восстанавливается за 10 сек. Можно активировать повторно, не дожидаясь полной перезарядки.");
        this.Text("MilitechHope-Buffs", "+10% к урону критических попаданий. +12 к выносливости.");
        this.Text("MilitechHope-Overheat-T5", "Изъян: больше 3 активаций подряд вызывают ошибку перегрева. Имплант принудительно отключается и полностью перезаряжается 12 сек.");
        this.Text("MilitechHope-Overheat-T5PP", "Изъян: больше 2 активаций подряд вызывают ошибку перегрева. Имплант принудительно отключается и полностью перезаряжается 12 сек.");

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
        this.Text("MilitechHope-Lore", "An experimental Militech prototype built for NUSA special forces. The batch was written off as destroyed while passing through the Arasaka port. The cooling system was never finished: Hope does not like being pushed without a break.");
        this.Text("MilitechHope-Stats-T5", "Slows time by 95% for 5 sec. Charge fully recovers in 10 sec. Can be activated again before it is fully recharged.");
        this.Text("MilitechHope-Stats-T5P", "Slows time by 97% for 7.5 sec. Charge fully recovers in 10 sec. Can be activated again before it is fully recharged.");
        this.Text("MilitechHope-Stats-T5PP", "Slows time by 99% for 10 sec. Charge fully recovers in 10 sec. Can be activated again before it is fully recharged.");
        this.Text("MilitechHope-Buffs", "+10% Crit Damage. +12 Stamina.");
        this.Text("MilitechHope-Overheat-T5", "Flaw: more than 3 activations in a row cause an overheat error. The implant shuts down and is forced into a full 12 sec recharge.");
        this.Text("MilitechHope-Overheat-T5PP", "Flaw: more than 2 activations in a row cause an overheat error. The implant shuts down and is forced into a full 12 sec recharge.");

        this.Text("MilitechHope-Msg-OverheatWarning", "HOPE: critical temperature. The next activation will overheat the implant.");
        this.Text("MilitechHope-Msg-Overheat", "HOPE: OVERHEAT ERROR. Forced recharge for 12 sec.");
        this.Text("MilitechHope-Msg-LevelLocked", "Incoming message is encrypted. You need level 40 to read it.");
        this.Text("MilitechHope-Msg-Sms", "New message [unknown number]: \"Saw you at the waterfront. The Militech case that got 'lost' at the port is now by the Columbarium at the cemetery. I marked it for you. Grab it before NUSA notices.\"");
        this.Text("MilitechHope-Msg-Complete", "Received: Militech \"Hope\" Sandevistan. Job \"Hope\" complete.");
    }
}

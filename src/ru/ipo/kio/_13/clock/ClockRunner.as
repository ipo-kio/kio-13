/**
 * Created by IntelliJ IDEA.
 * User: ilya
 * Date: 22.02.12
 * Time: 22:35
 * To change this template use File | Settings | File Templates.
 */
package ru.ipo.kio._13.clock {
import flash.display.Sprite;
import flash.events.Event;

import ru.ipo.kio._12.futurama.*;
import ru.ipo.kio.api.KioApi;
import ru.ipo.kio.base.KioBase;
[SWF(width="900", height="625")]
public class ClockRunner extends Sprite {
    public function ClockRunner() {
        if (stage)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        KioApi.language = KioApi.L_RU;

        KioBase.instance.initOneProblem(this, new ClockProblem(0));
    }
}
}

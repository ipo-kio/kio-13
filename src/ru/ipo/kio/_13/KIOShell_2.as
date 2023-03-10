/**
 * Created by IntelliJ IDEA.
 * User: ilya
 * Date: 09.02.11
 * Time: 21:41
 */
package ru.ipo.kio._13 {
import flash.display.Sprite;
import flash.events.Event;

import ru.ipo.kio._13.blocks.BlocksProblem;
import ru.ipo.kio._13.blocks.logdebug.BlockLogHandler;
import ru.ipo.kio._13.clock.ClockProblem;
import ru.ipo.kio._13.cut.CutProblem;

import ru.ipo.kio.api.KioApi;
import ru.ipo.kio.base.*;

public class KIOShell_2 extends Sprite {

    private var _level:int;

    public function KIOShell_2() {
        KioApi.language = KioApi.L_EN;
        _level = 2;

        if (stage)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        KioApi.localizationSelfTest(KioApi.L_RU);
        KioBase.instance.allowLogDebugger=true;
        KioBase.instance.addLogDebuggerHandler(new BlockLogHandler());

        KioBase.instance.init(this,
                [
                    new CutProblem(_level),
                    new BlocksProblem(_level),
                    new ClockProblem(_level)
                ],
                2013,
                _level
        );
    }

}
}

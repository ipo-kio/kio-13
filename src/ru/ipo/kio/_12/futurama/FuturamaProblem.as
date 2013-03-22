/**
 * Created by IntelliJ IDEA.
 * User: ilya
 * Date: 26.02.12
 * Time: 19:50
 * To change this template use File | Settings | File Templates.
 */
package ru.ipo.kio._12.futurama {
import flash.display.DisplayObject;

import ru.ipo.kio._12.futurama.model.Permutation;

import ru.ipo.kio._12.futurama.view.FuturamaField;
import ru.ipo.kio.api.KioApi;

import ru.ipo.kio.api.KioProblem;
import ru.ipo.kio.api.Settings;
import ru.ipo.kio.base.KioBase;

public class FuturamaProblem implements KioProblem {

    [Embed(source="loc/Futurama.ru.json-settings",mimeType="application/octet-stream")]
    public static var FUTURAMA_RU:Class;

    [Embed(source="resources/f1.jpg")]
    public static var f1:Class;
    [Embed(source="resources/f2.jpg")]
    public static var f2:Class;

    public static const ID:String = 'id';
    private var _n:int;
    private var _level:int;
    private var _display:FuturamaField;

    public function FuturamaProblem(level:int) {
        _level = level;
        _n = _level == 2 ? 9 : 8;

        KioApi.registerLocalization(ID, KioApi.L_RU, new Settings(FUTURAMA_RU).data);
        
        KioApi.initialize(this);

        _display = new FuturamaField(_n, level);
    }

    public function get n():int {
        return _n;
    }

//implementation of KIO Problem

    public function get id():String {
        return ID;
    }

    public function get year():int {
        return 2012;
    }

    public function get level():int {
        return _level;
    }

    public function get display():DisplayObject {
        return _display;
    }

    public function get solution():Object {
        return {perm: _display.perm.serialize()};
    }

    public function get best():Object {
        return _display.best;
    }

    public function loadSolution(solution:Object):Boolean {
        if (solution == 0)
            return false;

        var res:int = _display.perm.unserialize(solution.perm, ! KioApi.isChecker);
        
        return res == Permutation.STATUS_OK;
    }

    public function check(solution:Object):Object {
        return null; //no need to implement
    }

    public function compare(solution1:Object, solution2:Object):int {
        var len1:int = solution1.length;
        var len2:int = solution2.length;
        return len1 - len2;
    }

    [Embed(source='resources/intro_1.png')]
    private static var INTRO_1:Class;

    [Embed(source='resources/intro_2.png')]
    private static var INTRO_2:Class;

    public function get icon():Class {
        if (level == 2)
            return INTRO_2;
        else
            return INTRO_1;
    }

    public function get icon_help():Class {
        return f2;
    }

    public function get icon_statement():Class {
        return f1;
    }
}
}

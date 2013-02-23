/**
 * ��������� �������� ������, ����������� ��� ������� ������
 * 
 * @author: Vasiliy
 * @date: 21.02.13
 */
package ru.ipo.kio._13.clock.model.level {
import flash.display.Sprite;

public interface ITaskLevel {

    /**
     * ���������� ����� ������ (0,1,2)
     */
    function get level():int;

    /**
     * ���������� ���������� ������������ �����
     */
    function get correctRatio():Number

    /**
     * ���������� ������� ����������
     * @param precision
     * @return
     */
    function getFormattedPrecision(precision:Number):String;

    function getFormattedError(error:Number):String;
    
    function get icon_help():Class;
    
    function get icon_statement():Class;

    function getProductSprite():Sprite;

    function updateProductSprite():void;

    function get direction():int

    function truncate(absTransmissionError:Number):Number;


    function undoTruncate(relTransmissionError:Number):Number;
}
}

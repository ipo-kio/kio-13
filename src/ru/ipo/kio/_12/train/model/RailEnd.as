/**
 * ����� ������, �������� ������ ����������
 *
 * @author: Vasily Akimushkin
 * @since: 30.01.12
 */
package ru.ipo.kio._12.train.model {
import flash.geom.Point;

public class RailEnd extends VisibleEntity{

    private var _point:Point;

    private var _rail:Rail;
    
    private var _connectors:Vector.<RailConnector> = new Vector.<RailConnector>();
    
    public function RailEnd(point:Point, rail:Rail) {
        _point = point;
        _rail = rail;
    }

    public function get point():Point {
        return _point;
    }

    public function get rail():Rail {
        return _rail;
    }

    public function addConnector(connector:RailConnector):void{
        _connectors.push(connector);
    }

    public function get connectors():Vector.<RailConnector> {
        return _connectors;
    }

    public function isConnected(rail:Rail): Boolean{
        for(var i:int; i<_connectors.length; i++){
            if(_connectors[i].getAnotherRail(_rail)==rail){
                return true;
            }
        }
        return false;
    }
}
}
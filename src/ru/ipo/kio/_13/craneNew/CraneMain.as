/**
 * Created with IntelliJ IDEA.
 * User: kostya
 * Date: 05.02.13
 * Time: 23:11
 * To change this template use File | Settings | File Templates.
 */
package ru.ipo.kio._13.craneNew {
import flash.display.Sprite;


import ru.ipo.kio._13.craneNew.view.WorkspaceView;


public class CraneMain extends Sprite{
    public var cubeArray: Array = new Array();
    public var vCubeArray: Array = new Array();
    public var workView: WorkspaceView = new WorkspaceView(cubeArray, vCubeArray);


    public function CraneMain() {
        CraneProblem();


    }
    public function CraneProblem():void {
        addChild(workView);

    }


}
}

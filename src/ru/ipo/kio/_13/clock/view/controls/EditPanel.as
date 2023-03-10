/**
 *
 * @author: Vasiliy
 * @date: 23.02.13
 */
package ru.ipo.kio._13.clock.view.controls {

import flash.display.Sprite;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

import ru.ipo.kio._13.clock.ClockProblem;
import ru.ipo.kio._13.clock.ClockSprite;
import ru.ipo.kio._13.clock.ClockSprite;

import ru.ipo.kio._13.clock.model.SettingsHolder;
import ru.ipo.kio._13.clock.model.TransferGear;
import ru.ipo.kio._13.clock.model.TransmissionMechanism;
import ru.ipo.kio._13.clock.utils.ColorGenerator;
import ru.ipo.kio.api.KioApi;
import ru.ipo.kio.base.displays.ShellButton;

public class EditPanel extends AbstractPanel {

    private var _showButton:ShellButton;

    private var _hideButton:ShellButton;

    private var productSprite:Sprite;

    public function EditPanel() {
        var loc:Object = KioApi.getLocalization(ClockProblem.ID);

        productSprite = SettingsHolder.instance.levelImpl.getProductSprite();
        productSprite.x = 115;

        addChild(addSettingField("edit", 0, 0, 0, function (e:KeyboardEvent):void {}).label);

        addChild(createButton("add", 5, 25, function (event:MouseEvent):void {
            var newGear:TransferGear = new TransferGear(TransmissionMechanism.instance, 350, 200, 20, 10, ColorGenerator.nextHueOfColor(TransmissionMechanism.instance.transferGearList));
            KioApi.log(ClockProblem.ID, "BTN CREATE @S", newGear.id);
            TransmissionMechanism.instance.addTransferGear(newGear);
            TransmissionMechanism.instance.deactivateAll();
            TransmissionMechanism.instance.transferGearList[TransmissionMechanism.instance.transferGearList.length-1].isActive=true;
            TransmissionMechanism.instance.transferGearList[TransmissionMechanism.instance.transferGearList.length-1].view.update();

        }));

        addChild(createButton("delete", 5, 70, function (event:MouseEvent):void {
            var transferGear:TransferGear = TransmissionMechanism.instance.getActive();
            if(transferGear==null){
                KioApi.log(ClockProblem.ID, "BTN TRY DELETE EMPTY");
                ClockSprite.instance.showError(loc.messages.delete_empty);
            }else if (transferGear.isFirst()) {
                ClockSprite.instance.showError(loc.messages.delete_arrow);
                KioApi.log(ClockProblem.ID, "BTN TRY DELETE FIRST");
            }else{
                KioApi.log(ClockProblem.ID, "BTN DELETE @S", transferGear.id);
                TransmissionMechanism.instance.removeTransferGear(transferGear);
            }
        }));

        _showButton = createButton("show", 5, 115, function (event:MouseEvent):void {
            _showButton.visible=false;
            _hideButton.visible=true;
            ClockSprite.instance.addChild(productSprite);
            SettingsHolder.instance.levelImpl.updateProductSprite();
            KioApi.log(ClockProblem.ID, "BTN SHOW PRODUCT");
        });
        addChild(_showButton);


        _hideButton = createButton("hide", 5, 115, function (event:MouseEvent):void {
            _showButton.visible=true;
            _hideButton.visible=false;
            ClockSprite.instance.removeChild(productSprite);
            KioApi.log(ClockProblem.ID, "BTN HIDE PRODUCT");
        });
        addChild(_hideButton);

        _showButton.visible=true;
        _hideButton.visible=false;



    }

}
}

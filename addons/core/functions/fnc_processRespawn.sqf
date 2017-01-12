#include "script_component.hpp"

/*
    Name: TFAR_fnc_processRespawn

    Author(s):
        NKey
        L-H

    Description:
        Handles getting switching radios, handles whether a manpack must be added to the player or not.

    Parameters:
        Nothing

    Returns:
        Nothing

    Example:
        call TFAR_fnc_processRespawn;
*/
[{!(isNull player)},{
    TFAR_currentUnit = call TFAR_fnc_currentUnit;

    TF_respawnedAt = time;
    if (alive TFAR_currentUnit) then {
        if (TFAR_giveMicroDagrToSoldier)  then {
            TFAR_currentUnit linkItem "TFAR_microdagr";
        };

        true call TFAR_fnc_requestRadios;

                //Handle backpack replacement for group leaders
        if (leader TFAR_currentUnit != TFAR_currentUnit) exitWith {};
        if (!TFAR_giveLongRangeRadioToGroupLeaders or {backpack TFAR_currentUnit == "B_Parachute"} or {player call TFAR_fnc_isForcedCurator}) exitWith {};
        if ([(backpack TFAR_currentUnit), "tf_hasLRradio", 0] call TFAR_fnc_getConfigProperty == 1) exitWith {};

        private _items = backpackItems TFAR_currentUnit;
        private _backPack = unitBackpack TFAR_currentUnit;
        private _newItems = [];

        TFAR_currentUnit action ["putbag", TFAR_currentUnit];
        //In my tests in editor it took 0.89 seconds till the backpack is down
        [{backpack TFAR_currentUnit == ""},
        {
            TFAR_currentUnit addBackpack ((call TFAR_fnc_getDefaultRadioClasses) select 0);
            {
                if (TFAR_currentUnit canAddItemToBackpack _x) then {
                    TFAR_currentUnit addItemToBackpack _x;
                } else {
                    _newItems pushBack _x;
                };
                true;
            } count _items;

            clearItemCargoGlobal _backPack;
            clearMagazineCargoGlobal _backPack;
            clearWeaponCargoGlobal _backPack;
            {
                if (isClass (configFile >> "CfgMagazines" >> _x)) then{
                    _backPack addMagazineCargoGlobal [_x, 1];
                } else {
                    _backPack addItemCargoGlobal [_x, 1];
                    _backPack addWeaponCargoGlobal [_x, 1];
                };
                true;
            } count _newItems;
        }] call CBA_fnc_waitUntilAndExecute;
    };
}] call CBA_fnc_waitUntilAndExecute;
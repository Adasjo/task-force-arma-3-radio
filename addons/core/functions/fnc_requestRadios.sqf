#include "script_component.hpp"

/*
    Name: TFAR_fnc_requestRadios

    Author(s):
        NKey
        L-H

    Description:
        Checks whether the player needs to have radios converted to "instanced" versions,
        handles waiting for response from server with radio classnames and applying them to the player.

    Parameters:
        BOOLEAN - Replace already instanced Radios

    Returns:
        Nothing

    Example:
        call TFAR_fnc_requestRadios;
*/

private _fnc_CopySettings = {
    params ["_settingsCount", "_copyIndex", "_destination","_TF_SettingsToCopy"];

    if (_settingsCount > _copyIndex) then {
        if ([_destination, _TF_SettingsToCopy select _copyIndex] call TFAR_fnc_isSameRadio) then {
            private _source = _TF_SettingsToCopy select _copyIndex;
            private _variableName = format["%1_local", _source];
            private _localSettings = TFAR_RadioSettingsNamespace getVariable _variableName;
            if !(isNil "_variableName") then {
                [_destination, _localSettings, true] call TFAR_fnc_setSwSettings;
            };
        };
    };
    (_copyIndex + 1)
};
//#TODO somehow remove mutexing :x
//MUTEX_LOCK(TF_radio_request_mutex);

if ((time - TF_last_request_time < 3)) exitWith {/*MUTEX_UNLOCK(TF_radio_request_mutex);*/};
TF_last_request_time = time;

(_this call TFAR_fnc_radioToRequestCount) params ["_radiosToRequest","_TF_SettingsToCopy"];

if (_radiosToRequest isEqualTo []) exitWith {/*MUTEX_UNLOCK(TF_radio_request_mutex);*/};

//Answer EH
["TFAR_RadioRequestResponseEvent", {
    params ["_response"];
    private _copyIndex = 0;
    if (_response isEqualType []) then {
        private _radioCount = count _response;
        private _settingsCount = count _TF_SettingsToCopy;
        private _startIndex = 0;
        if (_radioCount > 0) then {
            if (TFAR_RadioReqLinkFirstItem) then {
                TFAR_RadioReqLinkFirstItem= false;
                TFAR_currentUnit linkItem (_response select 0);
                _copyIndex = [_settingsCount, _copyIndex, (_response select 0),_TF_SettingsToCopy] call _fnc_CopySettings;
                [(_response select 0), getPlayerUID player, true] call TFAR_fnc_setRadioOwner;
                _startIndex = 1;
            };
            _radioCount = _radioCount - 1;
            for "_index" from _startIndex to _radioCount do {
                TFAR_currentUnit addItem (_response select _index);
                _copyIndex = [_settingsCount, _copyIndex, (_response select _index),_TF_SettingsToCopy] call _fnc_CopySettings;
                [(_response select _index), getPlayerUID player, true] call TFAR_fnc_setRadioOwner;
            };
        };
    } else {
        hintC _response;
    };
    call TFAR_fnc_hideHint;
    //								unit, radios
    ["OnRadiosReceived", [TFAR_currentUnit, _response]] call TFAR_fnc_fireEventHandlers;

    ["TFAR_RadioRequestResponseEvent", _thisId] call CBA_fnc_removeEventHandler;
    [[15,"radioRequest",round ((diag_tickTime-TFAR_beta_RadioRequestStart)*1000)]] call TFAR_fnc_betaTracker;//#TODO remove on release

}] call CBA_fnc_addEventHandlerArgs;

[parseText(localize ("STR_wait_radio")), 10] call TFAR_fnc_showHint;
TFAR_beta_RadioRequestStart = diag_tickTime;//#TODO remove on release
//Send request
["TFAR_RadioRequestEvent", [_radiosToRequest,TFAR_currentUnit]] call CBA_fnc_serverEvent;

//MUTEX_UNLOCK(TF_radio_request_mutex);
#include "script_component.hpp"

/*
    Name: TFAR_fnc_setAdditionalLrStereo

    Author(s):
        NKey

    Description:
        Sets the stereo setting for additional channel the passed radio

    Parameters:
        0: ARRAY - Radio
            0: OBJECT- Radio object
            1: STRING - Radio ID
        1: NUMBER - Stereo setting : Range (0,2) (0 - Both, 1 - Left, 2 - Right)

    Returns:
        Nothing

    Example:
        [call TFAR_fnc_activeLrRadio, 1] call TFAR_fnc_setAdditionalLrStereo;
*/
params [["_radio",[],[[]],2],["_value",0,[0]]];
_radio params ["_radio_object", "_radio_qualifier"];

private _settings = _radio call TFAR_fnc_getLrSettings;
_settings set [TFAR_ADDITIONAL_STEREO_OFFSET, _value];
[_radio, _settings] call TFAR_fnc_setLrSettings;

//							unit, radio object,		radio ID			channel, additional
["OnLRstereoSet", [TFAR_currentUnit, _radio_object, _radio_qualifier, _value, true]] call TFAR_fnc_fireEventHandlers;
declare name "Hadrone";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

// 2 drones :
process = par(i, 2, (multi(i) :> _* (select_drone == i))) :>_ * on_off <:_,_;

select_drone = hslider("[1]Drones[style:radio{'1':0;'2':1}]", 0, 0, 1, 1);

on_off = checkbox("[0]ON / OFF");

// 4 sounds per drone :
multi(N) = par(i, 4, so.loop(drone(N), i) * volume(i));

drone(0) = soundfile("Drone_1 [url:{'Alonepad_reverb_stereo.flac'; 'Drone_C_filter_stereo.flac'; 'DRONEpad_test_stereo.flac'; 'gouttes_eau_mono.flac'}]", 1);
drone(1) = soundfile("Drone_2 [url:{'Pad_C_tremolo_stereo.flac'; 'Pedale_C_filter_stereo.flac'; 'rain_full_stereo.flac'; 'string_freeze_stereo.flac'}]", 1);

volume(0) = hslider("Volume 0 [acc:0 0 -8 0 8][hidden:1]", 0.5, 0, 1, 0.001) * (0.333) : fi.lowpass(1, 1);
volume(1) = hslider("Volume 1 [acc:0 1 -8 0 8][hidden:1]", 0.5, 0, 1, 0.001) * (0.333) : fi.lowpass(1, 1);
volume(2) = hslider("Volume 2 [acc:1 0 -8 0 8][hidden:1]", 0.5, 0, 1, 0.001) * (0.333) : fi.lowpass(1, 1);
volume(3) = hslider("Volume 3 [acc:1 1 -8 0 8][hidden:1]", 0.5, 0, 1, 0.001) * (0.333) : fi.lowpass(1, 1);

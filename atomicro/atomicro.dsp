declare name "atomicro";
declare author "Developpement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import("stdfaust.lib");

process = _ : *(0.5),fade_in : * : wr_index <: idelay_drywet,_ : select2(by_pass_delay);

// max size of buffer to be recorded
size = int(211680); // 4.8 seconds

/*------------------- Recording counter ------------------------*/
// increment of 1 (max = size+1) while record > 0 :
rec_counter = (0) : + ~(+(1) : * (record)) : min(size);
		
/*--------------------- Fade in / Fade out -----------------------*/
record = checkbox ("h:[0]/Record");
time_fade = 0.1;
base_amp = 1/(ma.SR * time_fade);
fade_in = select2(record, -1*base_amp,base_amp) : + ~(min(1) : max(base_amp));

/*--------------------- Read/Write buffer --------------------------*/
play = checkbox ("h:[0]/Play");
speed = int(1);
count_play = (fmod(_, select2(grain_mode, size, grain_size))~(+(speed) : *(play))) + (grain_start * grain_mode); // switch between normal and granulation mode
// reverse mode :
reverse_mode = checkbox("h:[1]/Reverse");
play_counter =  count_play <: select2(reverse_mode, _, (select2(grain_mode, size, grain_size + grain_start)-_ <: select2(grain_mode, _, +(grain_start - grain_size))));
// buffer :
wr_index = rwtable(size+1, 0.0, windex, _, rindex)
with {
    rindex = play_counter:int;
    windex = rec_counter:int;
};

/* -------------------- Granulation mode ---------------------------*/

grain_mode = checkbox("h:[1]/Granulation"):int;

grain_size = hslider("Grain size [hidden:1][acc:1 1 -8 0 8]", ((size/44100)/2), 0.005, (size/44100), 0.001) * (ma.SR): min(size-1) : max(110) : int;
grain_start = hslider("Grain start [hidden:1][acc:0 0 -8 0 8]", ((size/44100)/2), 0, (size/44100), 0.001) * (ma.SR) : min(size - (grain_size+1)) : max(grain_size+1) : int;

/* -------------------- Delay -----------------------------------*/

idelay = ((+ : de.sdelay(N, interp, dtime)) ~ *(fback))
with {
    N = int(2^19); // => max delay = number of samples
    interp = (75)*ma.SR*(0.001);
    dtime = (1800)*ma.SR*(0.001);
    fback = 0.5; // 50%
};

dry_wet(x,y) = (1-c)*x + c*y
with {
    c = 0.5;
};

idelay_drywet = _<: _ , idelay : dry_wet;

by_pass_delay = 1-(checkbox("h:[2]/Delay"));

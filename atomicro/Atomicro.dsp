declare name "Atomicro";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

process =_,(fade_in):*:wr_index<:idelay_drywet,_:select2(by_pass_delay):*(volume)
			with {
				volume = hslider("volume",1,-0.1,1,0.001):max(0):min(1):fi.lowpass(1,1);
				};

record = checkbox ("h:[0]/Record");
play = checkbox ("h:[0]/Play");


// max size of buffer to be recorded
size = 846720; //19.2 seconds


/*------------------- Recording counter ------------------------*/
// sah is like latch but reverse input
sah(x,c) = x * s : + ~ *(1-s)
with { s = ((c'<=0)&(c>0)); };

speed = hslider ("speed",1,0.25,2,0.001):fi.lowpass(1,1):max(0.25):min(2);

// increment de 1 (max = size+1) tant que fade_in > 0 :
rec_counter = (0):+~(+(1): * ((fade_in)>0)): min(size+1);

fin_rec = sah(rec_counter:mem,fade_in==0);// fin record si le fade est == O

			
/*--------------------- Fade in / Fade out -----------------------*/
time_fade = 0.1;
base_amp = 1,(ma.SR)*(time_fade):/;
fade_in = select2(record,(-1)*(base_amp),base_amp):+~(min((1)-base_amp):max(base_amp));

/*--------------------- Read/Write buffer --------------------------*/

count_play = fmod(_,max(1,int(fin_rec)))~(+(speed): *(play));
reverse_mode = checkbox("h:[1]/Reverse");
play_counter =  count_play <: select2(reverse_mode, _, abs(fin_rec-_));

wr_index = rwtable(size+1, 0., windex,_, rindex)
	with {
			rindex = select2(grain_mode,play_counter:int,grain_play_reverse:int);
			//rindex = grain_play_reverse : int;
			windex = rec_counter:int;
		};

/* -------------------- Granulation mode ---------------------------*/

grain_mode = checkbox("h:[1]/Grain mode"):int;

grain_size = hslider("Grain size [acc:1 1 -10 0 10]", ((size/44100)/2), 0.005, (size/44100), 0.001) * (ma.SR): min(fin_rec) : max(110) : int;
grain_start = hslider("Grain start [acc:0 0 -10 0 10]", ((size/44100)/2), 0, (size/44100), 0.001) * (ma.SR) : min(fin_rec - grain_size) : max(1) : int;

grain_play = (fmod(_,(max(1,int(fin_rec)) - (fin_rec - grain_size)) : min(fin_rec-grain_start) : max(1))~(+(speed): *(play)))  + (grain_start * play);
grain_play_reverse = grain_play <: select2(reverse_mode, _, abs((fin_rec - (fin_rec - grain_size) + (grain_start * play)) - _) : min(fin_rec-grain_start) : max(1));

/* -------------------- Delay -----------------------------------*/

idelay 	= ((+ : de.sdelay(N, interp, dtime)) ~ *(fback))
	with	{
				N = int(2^19); // => max delay = number of sample 
				interp = (75)*ma.SR*(0.001);
				dtime	= hslider("delay", 0, 0, 10000, 0.01)*ma.SR/1000.0;
				fback 	= hslider("feedback",0,0,100,0.1)/100.0; 
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = hslider("dry_wet",0,0,100,0.01):*(0.01):si.smooth(0.998);
					};

idelay_drywet =  _<: _ , idelay : dry_wet;

by_pass_delay = checkbox("h:[2]/By Pass Delay");
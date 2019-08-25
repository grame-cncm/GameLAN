declare name "Baliphone";
declare author "Developpement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

// 4 gamelans :
process = par(i, 4, (multi(i):> _* (select_gamelan == i))) :> bali_reverb * on_off <: limiter : _,_;

on_off = checkbox("[0]ON / OFF");

select_gamelan = hslider("[1]Gamelans[style:radio{'1':0;'2':1;'3':2;'4':3}]", 0, 0, 3, 1);

// 3 notes per gamelan :
multi(N) = par(i, 2, play(gamelan(N), i, i,(pitch == i)) * (0.666));

pitch = hslider("[3]Note [hidden: 1][acc:0 0 -10 0 10]", 1, 0, 2, 0.01) : rint/2;

gamelan(0) = soundfile("Gamelan_1 [url:{'Gamelan_1_1_C_gauche.flac'; 'Gamelan_3_2_Eb_gauche.flac'}]", 1);
gamelan(1) = soundfile("Gamelan_2 [url:{'Gamelan_2_1_D_center.flac';'Gamelan_4_1_G_droite.flac'}]", 1);
gamelan(2) = soundfile("Gamelan_3 [url:{'Gamelan_5_2_Ab_center.flac';'Gamelan_7_2_D_droite.flac'}]", 1);
gamelan(3) = soundfile("Gamelan_4 [url:{'Gamelan_6_3_C_gauche.flac'; 'Gamelan_8_3_Eb_center.flac'}]", 1);

//--------------- Player ---------------//
file_index = 0;

trigger(n,p) = hslider("[2]Trigger [hidden: 1][acc:1 0 -10 0 10]", 0.5, 0, 1, 0.1) * (p);

upfront(x) = (x-x')>0.99;

counter(sampleSize,n,p) = trigger(n,p) : upfront : decrease > (0.0) with{ //trig impulse to launch stream of 1
    decay(y) = y - (y>0.0)/sampleSize;
    decrease = +~decay;
};

index(sampleSize,n,p) = +(counter(sampleSize,n,p))~_ * (1 - (trigger(n,p) : upfront)) : int; //increment loop with reinit to 0 through reversed impulse (trig : upfront)

play(s, part,n,p) = (part, reader(s,n,p)) : outs(s)
    with {
        length(s) = part,0 : s : _,si.block(outputs(s)-1);
        srate(s) = part,0 : s : !,_,si.block(outputs(s)-2);
        outs(s) = s : si.block(2), si.bus(outputs(s)-2);
        reader(s,n,p) = index(length(s),n,p);
    };

//----------------- Limiter --------------//
limiter(x,y) =x*coeff,y*coeff

	with {
		epsilon =1/(44100*1.0);
		peak = max(abs(x),abs(y)):max~-(epsilon);
		coeff = 1.0/max(1.0,peak);
    };

//----------------- Reverb --------------//
bali_reverb = _<: instrReverb :>_;

instrReverb = _,_ <: *(reverbGain),*(reverbGain),*(1 - reverbGain),*(1 - reverbGain) :
re.zita_rev1_stereo(rdel,f1,f2,t60dc,t60m,fsmax),_,_ <: _,!,_,!,!,_,!,_ : +,+
    with {
       reverbGain = 1;
       roomSize = 0.7;
       rdel = 20;
       f1 = 200;
       f2 = 6000;
       t60dc = roomSize*3;
       t60m = roomSize*2;
       fsmax = 48000;
    };

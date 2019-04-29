declare name "Gamelan";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

// 3 gamelans :
process = par(i, 3, (multi(i) <: si.bus(6) :> _* (select_gamelan == i))) :>_ * on_off <:_,_;

select_gamelan = hslider("[1]Gamelans[style:radio{'1':0;'2':1;'3':2}]", 0, 0, 2, 1);

on_off = checkbox("[0]ON / OFF");

// 3 notes per gamelan :
multi(N) = par(i, 3, play(gamelan(N), i, i,(pitch == i)));

gamelan(0) = soundfile("Gamelan_1 [url:{'Gamelan_1_1_C_gauche.wav'; 'Gamelan_2_1_D_center.wav'; 'Gamelan_4_1_G_droite.wav'}]", 1);
gamelan(1) = soundfile("Gamelan_2 [url:{'Gamelan_3_2_Eb_gauche.wav'; 'Gamelan_5_2_Ab_center.wav'; 'Gamelan_7_2_D_droite.wav'}]", 1);
gamelan(2) = soundfile("Gamelan_3 [url:{'Gamelan_6_3_C_gauche.wav'; 'Gamelan_8_3_Eb_center.wav'; 'Gamelan_9_3_G_droite.wav'}]", 1);
//--------------- Player ---------------//

//sampleSize = table size index (i.e given out by soundfile 1st output)

file_index = 0;

trigger(n,p) = hslider("[2]Trigger [acc:1 0 -10 0 10]", 0.5, 0, 1, 0.1) * (p);
pitch = hslider("[3]Note [acc:0 0 -10 0 10]", 2, 0, 4, 0.01) : rint : /(2); 

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

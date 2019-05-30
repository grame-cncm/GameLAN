declare name "Sequenceur";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

N = 4;
onOff = checkbox("[1]ON/OFF");
sequenceur = par(i, N, play(sample(i), file_index, i) * (sample_pick == i)) :>_ * envelope;

process = sequenceur * onOff <:_,_;

seq_select = ba.beat(bps) : ba.pulse_countup_loop(15, 1) : hbargraph("Suivi",0,15);

bps = bpm.a25*(typeBpm == 7)+
    bpm.b37*(typeBpm == 6) +
    bpm.c50*(typeBpm == 5) +
    bpm.d62*(typeBpm == 4) +
    bpm.e75*(typeBpm == 3) +
    bpm.f100*(typeBpm == 2) +
    bpm.g125*(typeBpm == 1) +
    bpm.h150*(typeBpm == 0);

typeBpm = vslider("[1]Tempo [style:radio{'150 BPM':0;'125 BPM':1;'100 BPM':2;'75 BPM':3;'62.5 BPM':4;'50 BPM':5;'37.5 BPM':6;'25 BPM':7}]", 0, 0, 7, 1):int;
//typeBpm = floor(hslider("[2]Tempo", 0, 0, 7, 0.1)) : int;

bpm = environment { // bpm * 4, semiquaver (16th)
    a25 = 25 * 4;
    b37 = 37.5 * 4;
    c50 = 50 * 4;
    d62 = 62.5 * 4;
    e75 = 75 * 4;
    f100 = 100 * 4;
    g125 = 125 * 4;
    h150 = 150 * 4;
};

check(0) = checkbox("h:[04]/01") * 1;
check(1) = checkbox("h:[04]/02") * 2;
check(2) = checkbox("h:[05]/03") * 3;
check(3) = checkbox("h:[05]/04") * 4;
check(4) = checkbox("h:[06]/05") * 5;
check(5) = checkbox("h:[06]/06") * 6;
check(6) = checkbox("h:[07]/07") * 7;
check(7) = checkbox("h:[07]/08") * 8;
check(8) = checkbox("h:[08]/09") * 9;
check(9) = checkbox("h:[08]/10") * 10;
check(10) = checkbox("h:[09]/11") * 11;
check(11) = checkbox("h:[09]/12") * 12;
check(12) = checkbox("h:[10]/13") * 13;
check(13) = checkbox("h:[10]/14") * 14;
check(14) = checkbox("h:[11]/15") * 15;
check(15) = checkbox("h:[11]/16") * 16;

// ------------------------------------ Samples -------------------------------------

sample_pick = hslider("[0]Samples[style:radio{'Bip Square':0;'Hi-Hat':1;'Kick':2;'Snare':3}]", 0, 0, 3, 1);

sample(0) = soundfile("sample_2 [url:bipsquare_oneshot.flac]", 1);
sample(1) = soundfile("sample_4 [url:Hihat_oneshot_N.flac]", 1);
sample(2) = soundfile("sample_6 [url:Kick_oneshot_N.flac]", 1);
sample(3) = soundfile("sample_8 [url:Snare_oneshot_N.flac]", 1);

// ------------------------------------ Player --------------------------------------

file_index = 0;
trigger = par(i, 16, vgroup("[3]Steps",check(i)) == (seq_select + 1) : upfront) :>_;
upfront(x) = (x-x')>0.5;

counter(sampleSize) = trigger : decrease > (0.0)
    with { //trig impulse to launch stream of 1
        decay(y) = y - (y>0.0)/sampleSize;
        decrease = +~decay;
        sampleDuration = hslider("Decay[acc:0 0 -8 0 8][hidden:1]", 22050, 220, sampleSize, 1);// * 44100 : min(44100) : max(441) : int;
    };



index(sampleSize) = +(counter(sampleSize))~_ * (1 - (trigger : upfront)) : int; //increment loop with reinit to 0 through reversed impulse (trig : upfront)

play(s, part) = (part, reader(s)) : outs(s)
    with {
        length(s) = part,0 : s : _,si.block(outputs(s)-1);
        srate(s) = part,0 : s : !,_,si.block(outputs(s)-2);
        outs(s) = s : si.block(2), si.bus(outputs(s)-2);
        reader(s,n) = index(length(s));
    };

// ------------------------------------- Envelope -----------------------------------

envelope = en.asr(a,s,r,gate)  : fi.lowpass(1,1) with { //lowpass to prevent clicking 
  a = 0.000001; //in seconds
  s = 1; //gain btw 0 and 1
  r = 0.000002; //in seconds
  
  front(x) 	= abs(x-x') > 0.5;
  decay(y) = y - (y>0.0)/sampleDuration;
  release = + ~ decay;
  sampleDuration = hslider("Decay[acc:0 0 -8 0 8][hidden:1]", 22050, 220, 44100, 1);// * 44100 : min(44100) : max(441) : int;
  
  gate = trigger : front : release > (0.0);

};

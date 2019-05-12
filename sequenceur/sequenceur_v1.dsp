declare name "Sequenceur";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

N = 8;
onOff = checkbox("[0]ON/OFF");
sequenceur = hgroup("[1]Sequenceur", par(i, N, play(sample(i), file_index, i) * check(i)) :>_);

process = vgroup(" ", sequenceur * onOff <: _,reverb : dry_wet <:_,_);

seq_select = ba.beat(bps) : ba.pulse_countup_loop(7, 1);

bps = bpm.a25*(typeBpm == 7)+
    bpm.b37*(typeBpm == 6) +
    bpm.c50*(typeBpm == 5) +
    bpm.d62*(typeBpm == 4) +
    bpm.e75*(typeBpm == 3) +
    bpm.f100*(typeBpm == 2) +
    bpm.g125*(typeBpm == 1) +
    bpm.h150*(typeBpm == 0);

typeBpm = vslider("Tempo [style:radio{'150 BPM':0;'125 BPM':1;'100 BPM':2;'75 BPM':3;'62.5 BPM':4;'50 BPM':5;'37.5 BPM':6;'25 BPM':7}]", 0, 0, 7, 1);

bpm = environment {
    a25 = 25;
    b37 = 37.5;
    c50 = 50;
    d62 = 62.5;
    e75 = 75;
    f100 = 100;
    g125 = 125;
    h150 = 150;
};

check(0) = checkbox("v:[2]/Bip 1");
check(1) = checkbox("v:[2]/Bip 2");
check(2) = checkbox("v:[2]/Bip 3");
check(3) = checkbox("v:[2]/Bip 4");
check(4) = checkbox("v:[3]/Bip 5");
check(5) = checkbox("v:[3]/Bip 6");
check(6) = checkbox("v:[3]/Bip 7");
check(7) = checkbox("v:[3]/Bip 8");

// ------------------------------------ Samples -------------------------------------

sample(0) = soundfile("sample_1 [url:bipsquare_oneshot_N.wav]", 1);
sample(1) = soundfile("sample_2 [url:bipsquare_oneshot.wav]", 1);
sample(2) = soundfile("sample_3 [url:Hihat_oneshot_N.wav]", 1);
sample(3) = soundfile("sample_4 [url:Hihat_oneshot.wav]", 1);
sample(4) = soundfile("sample_5 [url:Kick_oneshot_N.wav]", 1);
sample(5) = soundfile("sample_6 [url:Kick_oneshot.wav]", 1);
sample(6) = soundfile("sample_7 [url:Snare_oneshot_N.wav]", 1);
sample(7) = soundfile("sample_8 [url:Snare_oneshot.wav]", 1);

// ------------------------------------ Player --------------------------------------

file_index = 0;
trigger(n) = seq_select == n;
upfront(x) = (x-x')>0.5;

counter(sampleSize, n) = trigger(n) : upfront : decrease > (0.0)
    with { //trig impulse to launch stream of 1
        decay(y) = y - (y>0.0)/sampleSize;
        decrease = +~decay;
    };

index(sampleSize,n) = +(counter(sampleSize,n))~_ * (1 - (trigger(n) : upfront)) : int; //increment loop with reinit to 0 through reversed impulse (trig : upfront)

play(s, part, n) = (part, reader(s,n)) : outs(s)
    with {
        length(s) = part,0 : s : _,si.block(outputs(s)-1);
        srate(s) = part,0 : s : !,_,si.block(outputs(s)-2);
        outs(s) = s : si.block(2), si.bus(outputs(s)-2);
        reader(s,n) = index(length(s),n);
    };

// ------------------------ Reverb ---------------------------------------------------------

reverb =  _<: instrReverb:>_;

instrReverb = _,_ <: *(reverbGain),*(reverbGain),*(1 - reverbGain),*(1 - reverbGain) :
re.zita_rev1_stereo(rdel,f1,f2,t60dc,t60m,fsmax),_,_ <: _,!,_,!,!,_,!,_ : +,+
    with {
       //reverbGain = hslider("v:Reverb/Reverberation Volume[acc:1 1 -10 0 10]",0.1,0.05,1,0.01) : si.smooth(0.999) : min(1) : max(0.05);
       reverbGain = 0.4;
       //roomSize = hslider("v:Reverb/Reverberation Room Size[acc:1 1 -10 0 10]", 0.1,0.05,2,0.01) : min(2) : max(0.05);
       roomSize = 0.4;
       rdel = 20;
       f1 = 200;
       f2 = 6000;
       t60dc = roomSize*3;
       t60m = roomSize*2;
       fsmax = 48000;
     };
 
 dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = vslider("dry_wet",0,0,100,0.01):*(0.01):si.smooth(0.998);
					};
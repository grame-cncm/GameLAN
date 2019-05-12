declare name "Sequenceur";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

N = 8;
onOff = checkbox("[0]ON/OFF");
sequenceur = par(i, N, play(sample(i), file_index, i) * (sample_pick == i)) :>_;

process = sequenceur * onOff <: _,reverb : dry_wet <:_,_;

seq_select = ba.beat(bps) : ba.pulse_countup_loop(15, 1);

bps = bpm.a25*(typeBpm == 7)+
    bpm.b37*(typeBpm == 6) +
    bpm.c50*(typeBpm == 5) +
    bpm.d62*(typeBpm == 4) +
    bpm.e75*(typeBpm == 3) +
    bpm.f100*(typeBpm == 2) +
    bpm.g125*(typeBpm == 1) +
    bpm.h150*(typeBpm == 0);

typeBpm = vslider("[1]Tempo [style:radio{'150 BPM':0;'125 BPM':1;'100 BPM':2;'75 BPM':3;'62.5 BPM':4;'50 BPM':5;'37.5 BPM':6;'25 BPM':7}]", 0, 0, 7, 1);

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

check(0) = checkbox("v:[2]/Bip 01") * 1;
check(1) = checkbox("v:[2]/Bip 02") * 2;
check(2) = checkbox("v:[2]/Bip 03") * 3;
check(3) = checkbox("v:[2]/Bip 04") * 4;
check(4) = checkbox("v:[2]/Bip 05") * 5;
check(5) = checkbox("v:[2]/Bip 06") * 6;
check(6) = checkbox("v:[2]/Bip 07") * 7;
check(7) = checkbox("v:[2]/Bip 08") * 8;
check(8) = checkbox("v:[3]/Bip 09") * 9;
check(9) = checkbox("v:[3]/Bip 10") * 10;
check(10) = checkbox("v:[3]/Bip 11") * 11;
check(11) = checkbox("v:[3]/Bip 12") * 12;
check(12) = checkbox("v:[3]/Bip 13") * 13;
check(13) = checkbox("v:[3]/Bip 14") * 14;
check(14) = checkbox("v:[3]/Bip 15") * 15;
check(15) = checkbox("v:[3]/Bip 16") * 16;

// ------------------------------------ Samples -------------------------------------

sample_pick = vslider("Samples [style:radio{'sample_1':0;'sample_2':1;'sample_3':2;'sample_4':3;'sample_5':4;'sample_6':5;'sample_7':6;'sample_8':7}]", 0, 0, 7, 1);

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
trigger = par(i, 16, check(i) == (seq_select + 1) : upfront) :>_;
upfront(x) = (x-x')>0.5;

counter(sampleSize) = trigger : decrease > (0.0)
    with { //trig impulse to launch stream of 1
        decay(y) = y - (y>0.0)/sampleSize;
        decrease = +~decay;
    };

index(sampleSize) = +(counter(sampleSize))~_ * (1 - (trigger : upfront)) : int; //increment loop with reinit to 0 through reversed impulse (trig : upfront)

play(s, part) = (part, reader(s)) : outs(s)
    with {
        length(s) = part,0 : s : _,si.block(outputs(s)-1);
        srate(s) = part,0 : s : !,_,si.block(outputs(s)-2);
        outs(s) = s : si.block(2), si.bus(outputs(s)-2);
        reader(s,n) = index(length(s));
    };

// ------------------------ Reverb ---------------------------------------------------------

  

freeverb = vgroup("Freeverb", fxctrl(fixedgain, wetSlider, stereoReverb(combfeed, allpassfeed, dampSlider, stereospread)));

reverb = _<: freeverb :>_;

//======================================================
//
//                      Freeverb
//        Faster version using fixed delays (20% gain)
//
//======================================================

// Constant Parameters
//--------------------

fixedgain   = 0.015; //value of the gain of fxctrl
scalewet    = 3.0;
scaledry    = 2.0;
scaledamp   = 0.4;
scaleroom   = 0.28;
offsetroom  = 0.7;
initialroom = 0.5;
initialdamp = 0.5;
initialwet  = 1.0/scalewet;
initialdry  = 0;
initialwidth= 1.0;
initialmode = 0.0;
freezemode  = 0.5;
stereospread= 23;
allpassfeed = 0.5; //feedback of the delays used in allpass filters

// Filter Parameters
//------------------

combtuningL1    = 1116;
combtuningL2    = 1188;
combtuningL3    = 1277;
combtuningL4    = 1356;
combtuningL5    = 1422;
combtuningL6    = 1491;
combtuningL7    = 1557;
combtuningL8    = 1617;

allpasstuningL1 = 556;
allpasstuningL2 = 441;
allpasstuningL3 = 341;
allpasstuningL4 = 225;

// Control Sliders
//--------------------
// Damp : filters the high frequencies of the echoes (especially active for great values of RoomSize)
// RoomSize : size of the reverberation room
// Dry : original signal
// Wet : reverberated signal

//dampSlider      = hslider("Damp",0.5, 0, 1, 0.025)*scaledamp;

dampSlider 		= 0.7*scaledamp;
roomsizeSlider  = 0.6 *scaleroom + offsetroom;
wetSlider       = 0.5;
combfeed        = roomsizeSlider;

// Comb and Allpass filters
//-------------------------

allpass(dt,fb) = (_,_ <: (*(fb),_:+:@(dt)), -) ~ _ : (!,_);

comb(dt, fb, damp) = (+:@(dt)) ~ (*(1-damp) : (+ ~ *(damp)) : *(fb));

// Reverb components
//------------------

monoReverb(fb1, fb2, damp, spread)
    = _ <:  comb(combtuningL1+spread, fb1, damp),
            comb(combtuningL2+spread, fb1, damp),
            comb(combtuningL3+spread, fb1, damp),
            comb(combtuningL4+spread, fb1, damp),
            comb(combtuningL5+spread, fb1, damp),
            comb(combtuningL6+spread, fb1, damp),
            comb(combtuningL7+spread, fb1, damp),
            comb(combtuningL8+spread, fb1, damp)
        +>
            allpass (allpasstuningL1+spread, fb2)
        :   allpass (allpasstuningL2+spread, fb2)
        :   allpass (allpasstuningL3+spread, fb2)
        :   allpass (allpasstuningL4+spread, fb2)
        ;

stereoReverb(fb1, fb2, damp, spread)
    = + <:  monoReverb(fb1, fb2, damp, 0), monoReverb(fb1, fb2, damp, spread);

// fxctrl : add an input gain and a wet-dry control to a stereo FX
//----------------------------------------------------------------

fxctrl(g,w,Fx) =  _,_ <: (*(g),*(g) : Fx : *(w),*(w)), *(1-w), *(1-w) +> _,_;
 
 dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = vslider("dry_wet [acc:0 0 -10 0 10][hidden:1]",0,0,100,0.01):*(0.01):si.smooth(0.998);
					};
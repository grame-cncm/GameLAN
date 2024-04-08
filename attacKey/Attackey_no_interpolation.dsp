import("stdfaust.lib");

declare name "Attackey";
declare author "Developpement Grame - CNCM par Elodie Rabibisoa, Romain Constant et Stéphane Letz.";
declare nvoices "12";
declare soundfiles "https://raw.githubusercontent.com/grame-cncm/GameLAN/master/attacKey";

// Specific syntax for faust2android, [style:keyboard] doesn't exist in iOS
process = vgroup("AttacKey [style:keyboard]", instru);

freq = hslider("freq", 349.23, 261.63, 783.99, 0.001);
gain = hslider("gain",0.5,0,1,0.01);
gate = button("gate");

instru = play(noteOn, instrument) * envelope * volume : attackey_reverb * 0.5 <:_,_;

envelope = en.adsr(0.01,0.01,0.9,0.1,gate)*gain;

instrument = hslider("Instruments[style:radio{'1':0;'2':1;'3':2;'4':3;'5':4}]", 0, 0, 4, 1);
volume = hslider("Volume [acc: 0 0 -8 0 0]", 1, 0, 1, 0.001):si.smoo;
noteOn = soundfile("Bell [url:{'Piano_F.flac';'Ether_F.flac';'Bell_F.flac';'Saw_F.flac';'Vibraphone_F.flac'}]", 1);

//--------------- Player ---------------//
trigger = gate;

upfront(x) = (x-x')>0.99;

//trig impulse to launch stream of 1 :
counter(sampleSize) = trigger : upfront : decrease > (0.0) with{ 
    decay(y) = y - (y>0.0)/sampleSize;
    decrease = +~decay;
};

speed = freq/(349.23*2); //reference pitch = F * 2 (midi keyboard plays one octave higher)

play(s, part) = (part, reader(s)) : outs(s)
with {
    length(s) = part,0 : s : _,si.block(outputs(s)-1);
    srate(s) = part,0 : s : !,_,si.block(outputs(s)-2);
    outs(s) = s : si.block(2), si.bus(outputs(s)-2);
    index(sampleSize) = +(speed*(float(srate(s)/ma.SR)*(counter(sampleSize))))~_ * (1 - (trigger : upfront)) : int; //increment loop with reinit to 0 through reversed impulse (trig : upfront)
    reader(s) = index(length(s));
};

// -------------------- Reverb ------------------- //
attackey_reverb = _<: instrReverb :>_;

instrReverb = _,_ <: *(reverbGain),*(reverbGain),*(1 - reverbGain),*(1 - reverbGain) :
re.zita_rev1_stereo(rdel,f1,f2,t60dc,t60m,fsmax),_,_ <: _,!,_,!,!,_,!,_ : +,+
with {
    reverbGain = 1;
    roomSize = 2;
    rdel = 20;
    f1 = 200;
    f2 = 6000;
    t60dc = roomSize*3;
    t60m = roomSize*2;
    fsmax = 48000;
};

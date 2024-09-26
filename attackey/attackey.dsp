import("stdfaust.lib");

declare name "attackey";
declare author "Developpement Grame - CNCM par Elodie Rabibisoa, Romain Constant et Stéphane Letz.";
declare nvoices "12";
declare soundfiles "https://raw.githubusercontent.com/grame-cncm/GameLAN/master/attacKey";

// Specific syntax for faust2android, [style:keyboard] doesn't exist in iOS
process = vgroup("Attackey [style:keyboard]", instru);

freq = hslider("freq", 349.23, 261.63, 783.99, 0.001);
gain = hslider("gain",0.5,0,1,0.01);
gate = button("gate");

envelope = en.adsr(0.01,0.01,0.9,0.1,gate)*gain;

instru = play1(noteOn, instrument) * envelope * volume : attackey_reverb * 0.5 <: _,_;

instrument = hslider("Instruments[style:radio{'1':0;'2':1;'3':2;'4':3;'5':4}]", 0, 0, 4, 1);
volume = hslider("Volume [acc: 0 0 -8 0 0][hidden:1]", 1, 0, 1, 0.001):si.smoo;
noteOn = soundfile("Instrus [url:{'Piano_F.flac';'Ether_F.flac';'Bell_F.flac';'Saw_F.flac';'Vibraphone_F.flac'}]", 1);
 
// -------------------- Interpolation Players ------------------- //

speed = freq/(349.23*2); //reference pitch = F * 2 (midi keyboard plays one octave higher)
srate(s, part) = part,0 : s : !,_,si.block(outputs(s)-2):float;

// Reset when button is pressed (0 when trig is on, 1 when trig is off)
reset(trig) = (trig-trig') <= 0; 

// Ramp with a given step, reset when trig is on
ramp(trig, step) = (+(step):*(reset(trig))) ~ _;

// Outputs
outs(s, level) = s : si.block(2), bus_level(outputs(s)-2) with { bus_level(n) = par(i,n,*(level)); };

// Plays a soundfile given a parametric 'reader'
player(s, part, reader, level) = (part, reader(s,part)) : outs(s,level);

// Plays a soundfile given a parametric 'reader' with linear interpolation
linear_player(s, part, reader, level) = (lplayer(id0), lplayer(id1))
		: ro.interleave(sound_outs, 2) 
		: par(i, sound_outs, linear(c))
with {
    lplayer(reader) = (part, reader) : outs(s, level);
    reader1 = reader(s, part);
    id0 = int(reader1);
    id1 = id0 + 1;
    c = reader1 - id0;
    sound_outs = outputs(s)-2;
    linear(c,v0,v1) = v0*(1-c)+v1*c;
};

// Plays a soundfile given a parametric 'reader' with cubic interpolation
cubic_player(s, part, reader, level) 
	= (lplayer(id0), lplayer(id1), lplayer(id2), lplayer(id3))
		: ro.interleave(sound_outs, 4) 
		: par(i, sound_outs, cubic(c))
with {
    lplayer(reader) = (part, reader) : outs(s, level);
    reader1 = reader(s, part);
    id0 = int(reader1);
    id1 = id0 + 1;
    id2 = id1 + 1;
    id3 = id2 + 1;
    c = reader1 - id0;
    sound_outs = outputs(s)-2;
    cubic(c,v0,v1,v2,v3) = v1 + 0.5 * c * (v2 - v0 + c * (2.0*v0 - 5.0*v1 + 4.0*v2 - v3 + c*(3.0*(v1 -v2) + v3 - v0)));
};
	
fullsample_reader(gate) = \(s,part).(ramp(gate, speed*srate(s,part)/ma.SR));

play1(s, part) = cubic_player(s, part, fullsample_reader(gate), 1);

// -------------------- Reverb ------------------- //
attackey_reverb = _<: instrReverb :>_;

instrReverb = _,_ <: *(reverbGain),*(reverbGain),*(1 - reverbGain),*(1 - reverbGain) :
re.zita_rev1_stereo(rdel,f1,f2,t60dc,t60m,fsmax),_,_ <: _,!,_,!,!,_,!,_ : +,+
with {
    reverbGain = 1;
    roomSize = 1;
    rdel = 20;
    f1 = 200;
    f2 = 6000;
    t60dc = roomSize*3;
    t60m = roomSize*2;
    fsmax = 48000;
};

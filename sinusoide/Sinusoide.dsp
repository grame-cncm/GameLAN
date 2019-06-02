declare name "Sinusoide";
declare author "Développement Grame - CNCM par Elodie Rabibisoa et Romain Constant.";

import ("stdfaust.lib");

N = 11;
process =  vgroup("MODE", mode_switch) : os.osc * 0.333 * volume <: sinus_reverb,_ : dry_wet <: limiter :>_ * on_off;

scale = par(i, N, freq(i) * choice(i)) :>_;
// numeric display of scale frequency:
//scale = par(i, N, freq(i) * choice(i)) : display :_;
// display = ba.selectn(11,freq_scale) : nentry("Frequence[unit:f]", 523.5, 523.5, 2093, 0.1):_;

freq_slide = vslider("h:[2]/slide [unit:Hz][acc:0 0 -10 0 10][hidden:1]",1046.5,523.5,2093.0,0.001) : si.smooth(0.998);
freq_scale = vslider("h:[2]/radio [unit:Hz][acc:0 0 -10 0 10][hidden:1][style:radio{'523.5':0;'587.3':1;'622.3':2;'784':3;'830.6':4;'1046.5':5;'1174.7':6;'1244.5':7;'1568':8;'1661.2':9;'2093':10}]", 5, 0, 10, 1);

freq(0) = 523.5;
freq(1) = 587.3;
freq(2) = 622.3;
freq(3) = 784;
freq(4) = 830.6;
freq(5) = 1046.5;
freq(6) = 1174.7;
freq(7) = 1244.5;
freq(8) = 1568;
freq(9) = 1661.2;
freq(10) = 2093;

choice(n) = abs(freq_scale - n) < 0.5;
volume = hslider("Volume [hidden:1][acc:1 0 -9 0 10]", 0.35, 0, 0.7, 0.001):si.smooth(0.991):min(1):max(0);
on_off = checkbox("ON / OFF");
toggle_mode = checkbox("[0]SLIDE / SCALE");
// Default mode = slide (0)
mode_switch = select2(toggle_mode, freq_slide, scale);

limiter(x,y) =x*coeff,y*coeff

	with {
		epsilon =1/(44100*1.0);
		peak = max(abs(x),abs(y)):max~-(epsilon);
		coeff = 1.0/max(1.0,peak);
    };

sinus_reverb = _<: instrReverb :>_;

instrReverb = _,_ <: *(reverbGain),*(reverbGain),*(1 - reverbGain),*(1 - reverbGain) :
re.zita_rev1_stereo(rdel,f1,f2,t60dc,t60m,fsmax),_,_ <: _,!,_,!,!,_,!,_ : +,+
    with {
       reverbGain = 0.4; //hslider("v:Reverb/Reverberation Volume",0.1,0.05,1,0.01) : si.smooth(0.999) : min(1) : max(0.05);
       roomSize = 2; //hslider("Reverberation Room Size", 0.1,0.05,2,0.01) : min(2) : max(0.05);
       rdel = 20;
       f1 = 200;
       f2 = 6000;
       t60dc = roomSize*3;
       t60m = roomSize*2;
       fsmax = 48000;
    };

dry_wet(x,y) = (x*c) + (y*(1-c)) with {
  c = vslider("[1] Dry/Wet Mix [hidden:1][style:knob]", 1,0,1.0,0.01) : si.smoo;
};
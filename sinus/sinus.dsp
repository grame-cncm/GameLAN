declare name "Sinus";
declare author "Elodie Rabibisoa & Romain Constant";

import ("stdfaust.lib");

N = 11;
process =  vgroup("MODE", mode_switch) : os.osc : zita : limiter :>_ * volume * on_off;

scale = par(i, N, freq(i) * choice(i)):>_;

freq_slide = vslider("h:[2]/slide [unit:Hz][acc:0 0 -10 0 10]",1046.5,523.5,2093.0,0.001) : si.smooth(0.998);
freq_scale = vslider("h:[2]/radio [unit:Hz][style:radio{'523.5':0;'587.3':1;'622.3':2;'784':3;'830.6':4;'1046.5':5;'1174.7':6;'1244.5':7;'1568':8;'1661.2':9;'2093':10}]", 0, 0, 10, 1);

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
volume = hslider("Volume [acc:1 0 -9 0 10]", 0.5, 0, 1, 0.001):si.smooth(0.991):min(1):max(0);
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

/* ---------------- Reverb Section ------------------- */

zita =_<:zita_rev3;

zita_rev3(x,y) = zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax,x,y) : out_eq
    with {
        //Reverb parameters:
        t60dc = hslider("[2] Low Frequencies Decay Time[unit:s][style:knob][tooltip: T60 = time (in seconds) to decay 60dB in low-frequency band]", 1.5, 0.5, 6, 0.01):si.smooth(0.999):min(6):max(0.5);
        t60m = hslider("[3] Mid Frequencies Decay Time[unit:s][style:knob][tooltip: T60 = time (in seconds) to decay 60dB in middle band]", 1.5, 0.5, 6, 0.01):si.smooth(0.999):min(6):max(0.5);
        fsmax = 48000.0;  // highest sampling rate that will be used
        rdel =50;
        f1 =500;
        f2 = 8000;

        out_eq = pareq_stereo(eq1f,eq1l,eq1q) : pareq_stereo(eq2f,eq2l,eq2q)
        with {
            pareq_stereo (eqf,eql,Q) = fi.peak_eq_cq (eql,eqf,Q) , fi.peak_eq_cq (eql,eqf,Q) ;
            eq1f =315;
            eq1l =0;
            eq1q =3;
            eq2f =3000;
            eq2l =0;
            eq2q =3;
        };
    };

//---------------------------------------- Zita_Rev1_Stereo4 -------------------------------------

// from effect.lib but with only N=4 for mobilephone application

zita_rev_fdn4(f1,f2,t60dc,t60m,fsmax) =
  ((si.bus(2*N) :> allpass_combs(N) : feedbackmatrix(N)) ~
   (delayfilters(N,freqs,durs) : fbdelaylines(N)))
with {
  N = 4;

  // Delay-line lengths in seconds:
  apdelays = (0.020346, 0.024421, 0.031604, 0.027333, 0.022904, 0.029291, 0.013458, 0.019123); // feedforward delays in seconds
  tdelays = ( 0.153129, 0.210389, 0.127837, 0.256891, 0.174713, 0.192303, 0.125000, 0.219991); // total delays in seconds
  tdelay(i) = floor(0.5 + ma.SR*ba.take(i+1,tdelays)); // samples
  apdelay(i) = floor(0.5 + ma.SR*ba.take(i+1,apdelays));
  fbdelay(i) = tdelay(i) - apdelay(i);
  // NOTE: Since ma.SR is not bounded at compile time, we can't use it to
  // allocate de.delay lines; hence, the fsmax parameter:
  tdelaymaxfs(i) = floor(0.5 + fsmax*ba.take(i+1,tdelays));
  apdelaymaxfs(i) = floor(0.5 + fsmax*ba.take(i+1,apdelays));
  fbdelaymaxfs(i) = tdelaymaxfs(i) - apdelaymaxfs(i);
  nextpow2(x) = ceil(log(x)/log(2.0));
  maxapdelay(i) = int(2.0^max(1.0,nextpow2(apdelaymaxfs(i))));
  maxfbdelay(i) = int(2.0^max(1.0,nextpow2(fbdelaymaxfs(i))));

  apcoeff(i) = select2(i&1,0.6,-0.6);  // allpass comb-filter coefficient
  allpass_combs(N) =
    par(i,N,(fi.allpass_comb(maxapdelay(i),apdelay(i),apcoeff(i)))); // filter.lib
  fbdelaylines(N) = par(i,N,(de.delay(maxfbdelay(i),(fbdelay(i)))));
  freqs = (f1,f2); durs = (t60dc,t60m);
  delayfilters(N,freqs,durs) = par(i,N,filter(i,freqs,durs));
  feedbackmatrix(N) = ro.hadamard(N); // math.lib

  staynormal = 10.0^(-20); // let signals decay well below LSB, but not to zero

  special_lowpass(g,f) = si.smooth(p) with {
    // unity-dc-gain fi.lowpass needs gain g at frequency f => quadratic formula:
    p = mbo2 - sqrt(max(0,mbo2*mbo2 - 1.0)); // other solution is unstable
    mbo2 = (1.0 - gs*c)/(1.0 - gs); // NOTE: must ensure |g|<1 (t60m finite)
    gs = g*g;
    c = cos(2.0*ma.PI*f/float(ma.SR));
  };

  filter(i,freqs,durs) = lowshelf_lowpass(i)/sqrt(float(N))+staynormal
  with {
    lowshelf_lowpass(i) = gM*low_shelf1_l(g0/gM,f(1)):special_lowpass(gM,f(2));
    low_shelf1_l(G0,fx,x) = x + (G0-1)*fi.lowpass(1,fx,x); // filter.lib
    g0 = g(0,i);
    gM = g(1,i);
    f(k) = ba.take(k,freqs);
    dur(j) = ba.take(j+1,durs);
    n60(j) = dur(j)*ma.SR; // decay time in samples
    g(j,i) = exp(-3.0*log(10.0)*tdelay(i)/n60(j));
  };
};

zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax) = re.zita_in_delay(rdel) : re.zita_distrib2(N) : zita_rev_fdn4(f1,f2,t60dc,t60m,fsmax) : output2(N)
    with {
         N = 4;
         output2(N) = outmix(N) : *(t1),*(t1);
         t1 = 0.37; // zita-rev1 linearly ramps from 0 to t1 over one buffer
         outmix(4) = !,ro.butterfly(2),!; // probably the result of some experimenting!
         outmix(N) = outmix(N/2),par(i,N/2,!);
    };
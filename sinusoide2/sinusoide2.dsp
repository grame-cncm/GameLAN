import ("stdfaust.lib");

declare name "sinusoide2";

process = oscil(freq) * volume * on_off <: sinus_reverb,_ : dry_wet <: limiter :>_ : ef.cubicnl(0,0);

on_off = ((ns<=1)|(mode==1)) : ba.line(1000); //cut the sound when no note is played

//====Frequency==========================

freq = ((move*12+50)*(mode==1)+mid*(mode==0)):ba.midikey2hz:si.smoo;

move = hslider("bouger[acc:0 0 -10 0 10][hidden:1]", 1,0,2,0.01);
ns = 1 / (do+dod+ree+red+mie+fa+fad+sol+sold+la+lad+sie); //note size on the slider
    do = checkbox("v:gamme/h:[0]./[0]do");
    dod = checkbox("v:gamme/h:[0]./[1]do#");
    ree = checkbox("v:gamme/h:[0]./[2]ré");
    red = checkbox("v:gamme/h:[1]./[0]ré#");
    mie = checkbox("v:gamme/h:[1]./[1]mi");
    fa = checkbox("v:gamme/h:[1]./[2]fa");
    fad = checkbox("v:gamme/h:[2]./[0]fa#");
    sol = checkbox("v:gamme/h:[2]./[1]sol");
    sold = checkbox("v:gamme/h:[2]./[2]sol#");
    la = checkbox("v:gamme/h:[3]./[0]la");
    lad = checkbox("v:gamme/h:[3]./[1]la#");
    sie = checkbox("v:gamme/h:[3]./[2]si");
nt = fmod(move,1);
oct = int(move);

mid = 50 + oct*12 +
    0*(nt>=0)*                                              (nt<ns*(do)) + 
    1*(nt>=ns*(do))*                                        (nt<ns*(do+dod))+ 
    2*(nt>=ns*(do+dod))*                                    (nt<ns*(do+dod+ree))+ 
    3*(nt>=ns*(do+dod+ree))*                                (nt<ns*(do+dod+ree+red))+ 
    4*(nt>=ns*(do+dod+ree+red))*                            (nt<ns*(do+dod+ree+red+mie))+ 
    5*(nt>=ns*(do+dod+ree+red+mie))*                        (nt<ns*(do+dod+ree+red+mie+fa))+
    6*(nt>=ns*(do+dod+ree+red+mie+fa))*                     (nt<ns*(do+dod+ree+red+mie+fa+fad))+
    7*(nt>=ns*(do+dod+ree+red+mie+fa+fad))*                 (nt<ns*(do+dod+ree+red+mie+fa+fad+sol))+
    8*(nt>=ns*(do+dod+ree+red+mie+fa+fad+sol))*             (nt<ns*(do+dod+ree+red+mie+fa+fad+sol+sold))+
    9*(nt>=ns*(do+dod+ree+red+mie+fa+fad+sol+sold))*        (nt<ns*(do+dod+ree+red+mie+fa+fad+sol+sold+la))+
   10*(nt>=ns*(do+dod+ree+red+mie+fa+fad+sol+sold+la))*     (nt<ns*(do+dod+ree+red+mie+fa+fad+sol+sold+la+lad))+
   11*(nt>=ns*(do+dod+ree+red+mie+fa+fad+sol+sold+la+lad));
//==============================

volume = hslider("Volume [hidden:1][acc:1 0 -9 0 10]", 0.35, 0, 0.7, 0.001):si.smooth(0.991):min(1):max(0);

// Default mode = slide (0)
mode = checkbox("[0]SLIDE");

oscil(f) = add(f)*(son==0) + fm(f)*(son==1) + lfo(f)*(son==2) + noi(f)*(son==3) + bell(f)*(son==4) with {
    son = hslider("son",0,0,4,1);
    add(f) = os.triangle(f)+0.3*os.triangle(f*2)+0.6*os.triangle(f*3)+0.3*os.triangle(f*5) / (1+0.3+0.6+0.3);
    fm(f) = os.osc(f * (1+os.osc(f*5)*0.6))* os.osc(f/8);
    lfo(f) = os.square(f):fi.resonlp(200+500*(1+os.osc(1)),2,1);
    noi(f) = no.noise<:fi.resonbp(f,20,0.6)+fi.resonbp(f*4,10,0.3);
    bell(f) =(ba.pulsen(10,11050)*no.noise) <: pm.germanBell(2,7000,0.25,0.3+0.1*os.osc(1)) + pm.marimba(f/4,3,7000,0.25,2) : _*0.5;
};

//----------------- Limiter -----------------------//
limiter(x,y) = x*coeff,y*coeff
with {
    epsilon = 1/(ma.SR*1.0);
    peak = max(abs(x),abs(y)) : max ~ -(epsilon);
    coeff = 1.0/max(1.0,peak);
};

//------------------ Reverb ----------------------//
sinus_reverb = _<: instrReverb :>_;

instrReverb = _,_ <: *(reverbGain),*(reverbGain),*(1 - reverbGain),*(1 - reverbGain) :
re.zita_rev1_stereo(rdel,f1,f2,t60dc,t60m,fsmax),_,_ <: _,!,_,!,!,_,!,_ : +,+
with {
   reverbGain = 0.4;
   roomSize = 2;
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
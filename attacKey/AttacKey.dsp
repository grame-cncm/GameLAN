import("stdfaust.lib");
declare nvoices "6";
// Specific syntax for faust2android


process = vgroup("AttacKey [style:keyboard]", instru);

freq = hslider("Freq", 100, 50, 200, 1) / 100;
gain = hslider("gain",0.5,0,1,0.01);
gate = button("gate");

envelope = en.adsr(0.01,0.01,0.8,0.1,gate)*gain;

instru = play(noteOn, 0) * envelope * volume;

volume = hslider("Volume [acc: 0 0 -10 0 10]", 0.5, 0, 1, 0.001);
noteOn = soundfile("Bell [url:Bell_F.flac]", 1);

//--------------- Player ---------------//

//sampleSize = table size index (i.e given out by soundfile 1st output)

trigger = gate;

upfront(x) = (x-x')>0.99;

counter(sampleSize) = trigger : upfront : decrease > (0.0) with{ //trig impulse to launch stream of 1
    decay(y) = y - (freq * ((y>0.0)/sampleSize));
    decrease = +~decay;
};


index(sampleSize) = +(counter(sampleSize))~_ * (1 - (trigger : upfront)) : int; //increment loop with reinit to 0 through reversed impulse (trig : upfront)

play(s, part) = (part, reader(s)) : outs(s)
    with {
        length(s) = part,0 : s : _,si.block(outputs(s)-1);
        srate(s) = part,0 : s : !,_,si.block(outputs(s)-2);
        outs(s) = s : si.block(2), si.bus(outputs(s)-2);
        reader(s) = index(length(s));
    };


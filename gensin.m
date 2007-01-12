# Simple logic to generate sine waves at 
#   given frequencies, for a given duration, and a given set of dBs
#   It also plots each wave and its freq spectrum
# v12Jan2007
# HanishKVC, 20Dec2006
#

global debug=1
global reverify=1
if(debug==0)
  frequencies=[50,100,200,400,600,800,1000,2000,4000,8000,10000,12000,14000,16000,18000,20000]
  samplingrate=44100
  amplitudesDB=[-67, -47, -27, -7, 0, 3, 6]
else
  frequencies=[50,400,1000,8000]
  #frequencies=[50, 100, 200, 400, 800, 1000, 2000, 4000, 8000, 10000, 12000, 14000, 16000, 18000, 20000]
  samplingrate=44100*1.0
  amplitudesDB=[-7, 0, 3, 6]
endif

duration=20
amplitudeMax=10**0.6
bitspersample=16

function [hist,freq] = freq_spectrum(data, samplingrate,freqsubmult)
  if(nargin < 3)
    freqsubmult = 2;
  endif
  if(nargin < 2)
    samplingrate = 44100;
  endif

  datalen=columns(data);
  hist=fft(data);
  freq=(1:datalen)*(samplingrate/datalen);

  hist=hist(1:datalen/freqsubmult);
  freq=freq(1:datalen/freqsubmult);
  #plot(freq,abs(hist));
endfunction

function [hist,freq]=freq_spectrum_log(data,samplingrate,freqsubmult)
  [hist,freq]=freq_spectrum(data,samplingrate,freqsubmult);
  hist=log10(hist);
endfunction

function data = freq_gen(freq, samprate, duration, ampratio, bits)
  data=ampratio*sin(2*pi*(freq/samprate)*(1:samprate*duration))*(2**(bits-1)-1);
  data=round(data);
endfunction

function data = freq_gen_square(freq, samprate, duration, ampratio, bits)
  data=freq_gen(freq,samprate,duration,ampratio,bits);
  #data=sign(data)*min(data);
  data=sign(data)*max(data);
endfunction

function samples_gen(freqs,samprate,duration,ampsdB,ampMax,bits)
  global debug
  global reverify

  entries=columns(freqs)+1;
  evalstr=strcat("gset terminal jpeg size 1600,",int2str(200*entries))
  eval(evalstr,"gset terminal jpeg size 1200,800")

  for a=1:columns(ampsdB)

    fflush(stdout);
    multiplot(0,0)
    printf(strcat("\n*** Working for ",int2str(ampsdB(a)),"dB ***\n"))
    evalstr=strcat("gset output \"/tmp/plot_",int2str(ampsdB(a)),"dB.jpg\"")
    eval(evalstr,"gset output /tmp/plot.jpg")
    if(reverify==1)
      multiplot(4,entries)
    else
      multiplot(2,entries)
    endif
  
    ampratio=(10**(ampsdB(a)/10)/ampMax) # -0.01
    dataAll=0
    for i=1:columns(freqs)
      printf(strcat("Generating freq",int2str(freqs(i)),"...\n"))

      data=ampratio*sin(2*pi*((1:samprate*duration)/samprate)*freqs(i))*((2**bits/2)-1);
      data=round(data);
      mplot(data(1:150))
      [ra,rf]=freq_spectrum(data,samprate);
      mplot(rf,abs(ra))
    
      fname=strcat("/tmp/data_",int2str(ampsdB(a)),"dB_",int2str(freqs(i)));
      saveaudio(fname,data,"raw",bits)
      if(reverify==1)
        dataT=loadaudio(fname,"raw",bits);
        dataT=dataT';
        mplot(dataT(1:150))
        [ra,rf]=freq_spectrum(dataT,samprate);
        mplot(rf,abs(ra))
      endif

      dataAll=dataAll+data;
    endfor

    printf "Generating the freq response...\n"
    mplot(dataAll(1:150))
    [ra,rf]=freq_spectrum(dataAll,samprate);
    mplot(rf,abs(ra))
  endfor
  multiplot(0,0)
endfunction

function test_diffDBs()
  multiplot(2,4);
  
  d1=freq_gen(1000,44100,5,0.5,16);
  mplot(d1(1:150))
  [rh,rf]=freq_spectrum(d1);
  mplot(rf,rh);
  
  d2=freq_gen(2000,44100,5,1,16);
  mplot(d2(1:150))
  [rh,rf]=freq_spectrum(d2);
  mplot(rf,rh);
  
  d3=freq_gen(1000,44100,5,1,16);
  mplot(d3(1:150))
  [rh,rf]=freq_spectrum(d3);
  mplot(rf,rh);
  
  d=d1+d2+d3;
  mplot(d(1:150))
  [rh,rf]=freq_spectrum(d);
  mplot(rf,rh);
  
  pause
  multiplot(0,0)
endfunction

function dB=dB_find(value,maxvalue,maxdb)
  dB=log10(value*(10**(maxdb/10))/maxvalue)*10
endfunction

function data=test_repDataOverwrite(data,interval)
  for i=1:interval:columns(data)
    data(i)=data(i+1);
  endfor
endfunction

function [dh,df]=harmonic_gen(fundfreq, hstart, hint, hstop, harmamp)
  df=freq_gen(fundfreq,44100,2,1,16);
  dh=df;
  for i=hstart:hint:hstop
    dt=freq_gen(fundfreq*i,44100,2,harmamp,16);
    dh=dh+dt;
  endfor
endfunction

function data=gen_1_0(count)
  a1=ones(1,count/2);
  a2=zeros(1,count/2);
  aT=[a1; a2];
  data=reshape(aT,1,count);
endfunction

function freq_spectrum_log_findabove(data,samplingrate,freqsubmult, min,max)
  [powers,freqs]=freq_spectrum_log(data,samplingrate,freqsubmult);
  plot(freqs,powers);
  pause
  powers=abs(powers);
  powers_c=clip(powers,[min,max]);
  powers_c=powers_c-min;
  ti=find(powers_c);
  printf ("freqs => log10(powers)_above_%g\n",min);
  for i = 1:length(ti)
    printf ("%g => %g(%g)\n",freqs(ti(i)),min+powers_c(ti(i)),powers_c(ti(i)));
  endfor
  plot(freqs,powers_c);
endfunction

function util_lecroydata_plot(datafile,samplingrate,freqsubmult,min,max)
  evalstr=strcat("dataT=load ",datafile,";")
  eval(evalstr,"printf \"Error loading data\n\"");
  data=dataT(1:length(dataT),2)';
  freq_spectrum_log_findabove(data,samplingrate,freqsubmult,min,max);
endfunction

function dummy_init
  printf("Welcome to gensin.m v12Jan2007\n");
endfunction

dummy_init
#test_diffDBs()
#samples_gen(frequencies,samplingrate,duration,amplitudesDB,amplitudeMax,bitspersample)

# misc
#[r1,r2]=freqz(sA,1,[],44100);
#plot(r2,r1), hold
#min,max,range,clip
#values,who,load, save,
#abs,real,floor,round,ceil
#find,nonzeros




# Simple logic to generate sine waves at 
#   given frequencies, for a given duration, and a given set of dBs
#   It also plots each wave and its freq spectrum
# v01Jan2017
# HanishKVC, 20Dec2006
#

global debug=1
global reverify=1
if(debug==1)
  #frequencies=[50,100,200,400,600,800,1000,2000,4000,8000,10000,12000,14000,16000,18000,20000]
  #amplitudesDB=[-67, -47, -27, -7, 0, 3, 6]
  global frequencies=[50,400,1000,8000]
  global amplitudesDB=[-7, 0, 3, 6]
  global samplingrate=44100*1.0
  global duration=20
  global amplitudeMax=10**0.6
  global bitspersample=16
endif


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
  global reverify

  numOfAmpsdB = columns(ampsdB);
  entries=columns(freqs)+1;
  hFigAll = figure()
  set(hFigAll, 'Position', [ 10, 10, 1024, 200*numOfAmpsdB ])
  sFigAllSetSize = strcat("-S1600,",int2str(200*numOfAmpsdB))
  hFigCur = figure()
  set(hFigCur, 'Position', [ 10, 10, 1600, 200*entries ])
  sFigCurSetSize = strcat("-S1600,",int2str(200*entries))
  #set(hFigCur, "visible", "off")

  for a=1:columns(ampsdB)

    fflush(stdout);
    figure(hFigCur)
    printf(strcat("\n*** Working for ",int2str(ampsdB(a)),"dB ***\n"))
    plotRs = entries
    if(reverify==1)
      plotCs = 4
    else
      plotCs = 2
    endif

    ampratio=(10**(ampsdB(a)/10)/ampMax) # -0.01
    dataAll=0
    for i=1:columns(freqs)
      printf(strcat("Generating freq",int2str(freqs(i)),"...\n"))

      data=ampratio*sin(2*pi*((1:samprate*duration)/samprate)*freqs(i))*((2**bits/2)-1);
      data=round(data);
      subplot(plotRs, plotCs, (i-1)*plotCs+1)
      plot(data(1:150))
      title(strcat("Freq:Data = ",int2str(freqs(i))))
      [ra,rf]=freq_spectrum(data,samprate);
      subplot(plotRs, plotCs, (i-1)*plotCs+2)
      plot(rf,abs(ra))
      title("Spectrum")
    
      fname=strcat("/tmp/data_",int2str(ampsdB(a)),"dB_",int2str(freqs(i)));
      saveaudio(fname,data,"raw",bits)
      if(reverify==1)
        dataT=loadaudio(fname,"raw",bits);
        dataT=dataT';
        subplot(plotRs, plotCs, (i-1)*plotCs+3)
        plot(dataT(1:150))
        title("ReLoaded")
        [ra,rf]=freq_spectrum(dataT,samprate);
        subplot(plotRs, plotCs, (i-1)*plotCs+4)
        plot(rf,abs(ra))
        title("DoVerify")
      endif

      dataAll=dataAll+data;
    endfor

    subplot(plotRs, plotCs, i*plotCs+1)
    plot(dataAll(1:150))
    printf "Generating the freq response...\n"
    [ra,rf]=freq_spectrum(dataAll,samprate);
    subplot(plotRs, plotCs, i*plotCs+2)
    plot(rf,abs(ra))
    #evalstr=strcat("print hFigCur -dpdfcairo \"/tmp/plot_",int2str(ampsdB(a)),"dB.pdf\"")
    #saveas(hFigCur,strcat("/tmp/plot_",int2str(ampsdB(a)),"dB.png"))
    print(hFigCur,strcat("/tmp/plot_",int2str(ampsdB(a)),"dB.png"), sFigCurSetSize)

    figure(hFigAll)
    subplot(numOfAmpsdB, 2, (a-1)*2+1)
    plot(dataAll(1:150))
    title(strcat("Freqs: ",mat2str(freqs),", At dB=",int2str(ampsdB(a))))
    subplot(numOfAmpsdB, 2, (a-1)*2+2)
    plot(rf,abs(ra))
  endfor
  #print(hFigAll, "/tmp/plotAll.jpg", '-djpg','-r300')
  print(hFigAll, "/tmp/plotAll", '-dpng',sFigAllSetSize)

  pause
  close(hFigCur)
  close(hFigAll)
endfunction

function test_diffDBs()
  
  d1=freq_gen(1000,44100,5,0.5,16);
  subplot(4,2,1);
  plot(d1(1:150))
  [rh,rf]=freq_spectrum(d1);
  subplot(4,2,2);
  plot(rf,rh);
  
  d2=freq_gen(2000,44100,5,1,16);
  subplot(4,2,3);
  plot(d2(1:150))
  [rh,rf]=freq_spectrum(d2);
  subplot(4,2,4);
  plot(rf,rh);
  
  d3=freq_gen(1000,44100,5,1,16);
  subplot(4,2,5);
  plot(d3(1:150))
  [rh,rf]=freq_spectrum(d3);
  subplot(4,2,6);
  plot(rf,rh);
  
  d=d1+d2+d3;
  subplot(4,2,7);
  plot(d(1:150))
  [rh,rf]=freq_spectrum(d);
  subplot(4,2,8);
  plot(rf,rh);
  print("/tmp/test_diffDBs.png")
  pause
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

function freqs=util_octave_scale(base,nextoctave,count)
  for i = 0:count
    freqs(i+1)=base*((2*nextoctave)**i);
  endfor
endfunction

function freqs=util_freqs_required
  fs1=util_octave_scale(63,2,4);
  fs2=util_octave_scale(100,2,4);
  fs3=util_octave_scale(160,2,4);
  freqs=sort([fs1,fs2,fs3]);
endfunction

function util_samples_gen
  global samplingrate
  global duration
  global amplitudeMax
  global bitspersample
  samplingrate
  duration
  amplitudeMax
  bitspersample
  
  printf("Press Any key to Generate samples for different dBs...\n");
  pause
  frequencies=[63,1000]
  amplitudesDB=[-7, 0, 3, 6]
  samples_gen(frequencies,samplingrate,duration,amplitudesDB,amplitudeMax,bitspersample);

  printf("Press Any key to Generate samples for different frequencies...\n");
  pause
  # Based on Octaves of 31.5 (octave band spectrum)
  frequencies=[31,63,125,250,500,1000,2000,4000,8000,16000]
  # Based on 1/3-Octaves
  #frequencies=[25,40,63,100,160,250,400,630,1000,1600,2500,4000,6300,10000,16000]
  # Based on 2nd octaves of 63,100,160
  #frequencies=[50,63,100,160,250,400,640,1000,1600,2500,4000,6300,10000,16000,25000]
  amplitudesDB=[0, 3]
  samples_gen(frequencies,samplingrate,duration,amplitudesDB,amplitudeMax,bitspersample);
endfunction

function dummy_init
  printf("Welcome to gensin.m v01Jan2017\n");
  printf("Switching from new pathetic qt/opengl based plot toolkit to gnuplot\n");
  graphics_toolkit("gnuplot")
endfunction

# ***********

function modulate(data, data_sr, carrier_sr)
  samples=carrier_sr/data_sr;
  duration=length(data)/data_sr;
  carrier=freq_gen(carrier_sr/8,carrier_sr,duration,1,16);
  di=1;
  on modulate(data, data_sr, carrier_sr)
  for i=1:length(carrier)
  endfor
endfunction

# ***********

dummy_init()
#test_diffDBs()
#util_samples_gen()

# misc
#[r1,r2]=freqz(sA,1,[],44100);
#plot(r2,r1), hold
#min,max,range,clip
#values,who,load, save,
#abs,real,floor,round,ceil
#find,nonzeros




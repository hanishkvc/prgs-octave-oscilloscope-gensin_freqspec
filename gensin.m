# Simple logic to generate sine waves at 
#   given frequencies, for a given duration, and a given set of dBs
#   It also plots each wave and its freq spectrum
# v28Dec2006
# HanishKVC, 20Dec2006
#

debug=1
reverify=1
if(debug==0)
  freqs=[50,100,200,400,600,800,1000,2000,4000,8000,10000,12000,14000,16000,18000,20000]
  samprate=44100
  ampsdB=[-67, -47, -27, -7, 0, 3, 6]
else
  freqs=[50,400,1000,8000]
  samprate=44100*1.0
  ampsdB=[-67, -7, 0, 3, 6]
endif

duration=5
ampMax=10**0.6
bits=16

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

entries=columns(freqs)+1;
evalstr=strcat("gset terminal jpeg size 1200,",int2str(200*entries))
eval(evalstr,"gset terminal jpeg size 1200,800")

for a=1:columns(ampsdB)

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

    data=ampratio*sin(2*pi*((1:samprate*duration)/samprate)*freqs(i))*((2**bits-1)/2);
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


# Simple logic to generate a sine wave at 
#   a given frequency, for a given duration, and a given db
# HanishKVC, v20Dec2006_1722
#

debug=1
if(debug==0)
  freqs=[50,100,200,400,600,800,1000,2000,4000,8000,10000,12000,14000,16000,18000,20000]
  samprate=44100
  ampsdB=[-67, -47, -27, -7, 0, 3, 6]
else
  freqs=[100,1000,10000]
  samprate=44100*1.0
  ampsdB=[-67, -7, 0, 6]
endif

duration=5
ampMax=10**0.6

bits=16

for a=1:columns(ampsdB)
  ampratio=10**(ampsdB(a)/10)/ampMax
  for i=1:columns(freqs)
    printf "Generating freq",freqs(i)
    data=ampratio*sin(2*pi*((1:samprate*duration)/samprate)*freqs(i))*(2**bits-1);
    plot(data(1:50))
    pause
    saveaudio(strcat("/tmp/data_",int2str(ampsdB(a)),"_",int2str(freqs(i))),data,"raw",bits)
  endfor
endfor


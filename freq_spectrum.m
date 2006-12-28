
function [hist,freq] = freq_spectrum(data, samplingrate)
  datalen=columns(data);
  hist=fft(data);
  freq=(1:datalen)*(samplingrate/datalen);
  #plot(freq,abs(hist));
endfunction

function freq,hist = freq_spectrum_evolve(data, samplingrate)
  datalen=columns(data);
  if(datalen < samplingrate)
    hist=fft(data);
    freq=1:samplingrate/datalen:samplingrate;
  endif
  if(datalen == samplingrate)
    hist=fft(data);
    freq=1:samplingrate;
  endif
  if(datalen > samplingrate)
    hist=fft(data);
    freq=(1:datalen)*(samplingrate/datalen)
  endif
  plot(freq,abs(hist));
endfunction

function junk_spectrum
  if(datalen > samplingrate)
    passes=columns(data)/samplingrate;
    hist=0
    for i=0:passes-1
      res=fft(data(i*samplingrate+1:(i+1)*samplingrate));
      hist=hist+res;
    endfor
  endif
  if((datalen > samplingrate) && 0 )
    histT1=fft(data);
    passes=columns(data)/samplingrate;
    for i=0:samplingrate-1
      hist(i)=sum(histT1(i*passes:(i+1)*passes))/passes;
    endfor
  endif
endfunction


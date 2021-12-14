function varargout=oudespecgram(x,nFFT,Fs,window,noverlap) %#ok<INUSD>
%oudespecgram - specgram - met hulp voor input
%
%       [B,F,T]=oudespecgram(x,nFFT,Fs,window,noverlap);

if nargin>5
	error('te veel inputs!')
end
in=cell(1,nargin);
sIn={'x','nFFT','Fs','window','noverlap'};
for i=1:length(in)
	in{i}=eval(sIn{i});
end
varargout=cell(1,nargout);
[varargout{:}]=specgram(in{:});

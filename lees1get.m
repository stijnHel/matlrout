function [x,n,s] = lees1get(fid,ext)
% LEES1GET - Leest 1 getal
%  [x,n]=lees1get(fid,ext)
%      fid = file-ID, als string, string wordt gelezen
%      ext = (als gegeven) letter waarbij gestopt wordt met lezen
%      n = aantal karakters gelezen
%  In geval van een string, werkt dit enkel met maximum 1 ext-letter
if ~exist('ext')
	ext=[];
end
if isstr(fid)
 [x,nx,err,n] = sscanf(fid,['%g' ext],1);
 if nargout>2
  s=fid(n:length(fid));
 end
else
 getalletters=zeros(255,1);
 getalletters([abs(['+','-','.']),abs('0'):abs('9')])=ones(13,1);
 nl=0;
 while 1
   s1=fread(fid,1,'char');
   nl=nl+1;
   if isempty(s1)
     x=[];
     return
   end
   if getalletters(abs(s1))
     break
   end
 end

 sx=setstr(s1);

 while 1
   s1=fread(fid,1,'char');
   nl=nl+1;
   if isempty(s1) | (any(ext==s1))
     break
   end
   if ~((s1=='+') | (s1=='-') | (s1=='.') | ((s1>='0') & (s1<='9')))
     break
   end
   sx=[sx s1];
 end
 x=str2num(sx);
 if nargout>0
  n=nl;
 end
end

function [x,n,s] = lees1str(fid,ext)
% LEES1STR - Leest 1 string
%  [x,n,s]=lees1str(fid,ext)
%      fid = file-ID, als string, string wordt gelezen
%      ext = (als gegeven) letter waarbij gestopt wordt met lezen
%      n = aantal karakters gelezen
if ~exist('ext')
	ext=[];
end
if isstr(fid)
 [lstr,ng]=lees1get(fid,',');
 x=fid(ng:ng-1+lstr);
 if nargout>2
  s=fid(ng:ng-1+lstr);
 end
else
 getalletters=zeros(255,1);
 getalletters(['+','-','.','0':'9'])=ones(13,1);
 nl=0;
 while 1
   s1=fread(fid,1,'char');
   nl=nl+1;
   if s1==[]
     x=[];
     return
   end
   if getalletters(s1)
     break
   end
 end

 sx=setstr(s1);

 while 1
   s1=fread(fid,1,'char');
   nl=nl+1;
   if (s1==[]) | (any(ext==s1))
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

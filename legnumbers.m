function legnumbers(Z,form,pre,post)
% LEGNUMBERS - Make legend based on a numberlist
%        legnumbers(Z,form[,pre[,post]])
%             Z : numberlist
%             form : formaatstring (bijvoorbeeld '%3.0f')
%             pre, post
%----moet nog uitgebreid worden..-----
% werkt nu enkel met vaste groottes van formaten

if ~exist('pre','var')
	pre='';
end
if ~exist('post','var')
	post='';
end
s1=sprintf(form,Z(1));
totlen=length(pre)+length(post)+length(s1);
S=reshape(sprintf([pre form post],Z),totlen,[])';
legend(S)

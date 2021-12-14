function [i1,i2]=findedges(B,edge)
%findedges - Find edges of a signal
%     [i1,i2]=findedges(B,edge);
%     ii=findedges(B,edge);
%
%   edge : +1 or -1 (pos value or negative)
%          [+1 -1] both edges
%                  if one output result is put in array with possible zeros
%                     at start or end
%          default is +1 with maximum one output, [+1 -1] for two outputs
%   B is boolean vector or vector with threshold 0

if min(size(B))~=1
	error('Works only for vectors!')
end
if nargin<2||isempty(edge)
	if nargout<2
		edge=1;
	else
		edge=[1 -1];
	end
end
if length(edge)>2
	error('maximum two types of edges!!')
end
if isnumeric(B)
	B=B>0;
end
B=B(:);

ii=cell(1,length(edge));
for i=1:length(edge)
	if edge(i)>0
		ii{i}=find(B(2:end)&~B(1:end-1));
	else
		ii{i}=find(~B(2:end)&B(1:end-1));
	end
end
if length(edge)==1
	i1=ii{1};
elseif nargout==2
	i1=ii{1};
	i2=ii{2};
elseif isempty(ii{1})
	if isempty(ii{2})
		i1=zeros(0,2);
	else
		i1=[0 ii{2}];
	end
elseif isempty(ii{2})
	i1=[ii{1} 0];
else
	if ii{1}(1)>ii{2}(1)
		ii{1}=[0;ii{1}];
	end
	if length(ii{1})>length(ii{2})
		ii{2}(end+1)=0;
	end
	i1=cat(2,ii{:});
end

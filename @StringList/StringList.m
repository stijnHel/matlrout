%StringList - Class to keep a list of strings
classdef StringList < handle
	properties
		List;
		sizList=0;
		sizStep=100;
	end		% properties
	methods
		function L=StringList(sStep)
			if nargin
				L.sizStep=sStep;
			end
			L.List=cell(1,L.sizStep);
		end
		function [bNew,i]=Add(L,element)
			B=strcmp(element,L.List(1:L.sizList));
			if any(B)
				i=find(B);
				bNew=false;
			else
				bNew=true;
				i=L.sizList+1;
				if i>length(L.List)&&L.sizStep>1
					L.List{L.sizList+L.sizStep}='';	% resever memoty
				end
				L.List{i}=element;
				L.sizList=i;
			end
		end %	 Add
		function bExist=Test(L,element)
			bExist=any(strcmp(element,L.List(1:L.sizList)));
		end		% Test
		function Lst=Get(L,i)
			if nargin==1
				Lst=L.List(1:L.sizList);
			elseif any(i<0|i>L.sizList)
				error('index out of bounds')
			elseif isscalar(i)
				Lst=L.List{i};
			else
				Lst=L.List(i);
			end
		end		% Get
		function n=length(L)
			n=L.sizList;
		end		% length
		function n=size(L,d)
			n=[L.sizList,1];
			if nargin>1
				if ~isscalar(d)||d<0
					error('Wrong input')
				elseif d>2
					n=1;
				else
					n=n(d);
				end
			end
		end		% size
		function s=subsref(L,S)
			if length(S)==1&&strcmp(S.type,'.')
				error('No ''.''-referencing allowed')
			elseif length(S)~=1||~strcmp(S.type,'()')||length(S.subs)<1||length(S.subs)>2
				error('Only simple indexing can be done')
			else
				s=Get(L,S.subs{1});
			end
		end		% subsref
	end		% methods
end		% classdef StringList

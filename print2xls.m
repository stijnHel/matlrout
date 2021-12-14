function E=print2xls(s)
% PRINT2XLS - Schrijf data naar Excel
%
% print2xls(s)
%     voorlopig werkt dit alleen maar voor eenvoudige arrays en cell-arrays

excel=actxserver('Excel.Application');
set(excel,'visible',1);
invoke(excel.WorkBooks,'Add');
rij=1;
col=1;

if isnumeric(s)
	if length(size(s))>2
		fprintf('!!!!!!werkt niet voor meer dimenties dan 2!!!!!\')
	else
		for i=1:size(s,1)
			for j=1:size(s,2)
				RC=rijcol(i,j);
				set(get(excel.Activesheet,'Range',RC,RC),'Value',sprintf('%g',s(i,j)));
			end
		end
	end
elseif iscell(s)
	if ndims(s)>2
		fprintf('!!!!!!werkt niet voor meer dimenties dan 2!!!!!\')
	else
		for i=1:size(s,1)
			for j=1:size(s,2)
				RC=rijcol(i,j);
				if isempty(s{i,j})
					%-----
				elseif isnumeric(s{i,j})
					if prod(size(s))~=1
						set(get(excel.Activesheet,'Range',RC,RC),'Value','array');
					else
						set(get(excel.Activesheet,'Range',RC,RC),'Value',sprintf('%g',s{i,j}));
					end
				elseif ischar(s{i,j})
					set(get(excel.Activesheet,'Range',RC,RC),'Value',s{i,j});
				end	% numeric
			end	% for j
		end	% for i
	end	% ndims<=2
else	% no numeric or cell
	fprintf('!!!!!!voorlopig enkel voor numerische en cell-arrays (niet voor %s)\n',class(s))
end
if nargout
	E=excel;
else
	delete(excel);
end

function RC=rijcol(rij,col)
if col<27
	RC=char('A'+(col-1));
else
	RC=char('A'+[floor((col-27)/26) rem(col-1,26)]);
end
RC=[RC num2str(rij)];

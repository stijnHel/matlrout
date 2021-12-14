function jpeg=maakjpeg(c,ind,f);
% CSWF/MAAKJPEG - Maakt JPEG-data van data in SWF
%    jpeg=maakjpeg(c,ind[,f])	(f nog niet gebruikt)
%          ind : [framenr(:) index(:)]

if ~exist('ind')|isempty(ind)
	ind=zoekjpegs(c);
	ind(ind(:,1)==0,:)=[];
	ind=ind(:,2:3);
end

i_table=zoektags(c,8);
if ~isempty(i_table)
	table=c.frames{i_table(1)}(i_table(2)).tagData;
end

if nargout
	jpeg={};
end
IDs=[];
for i=1:size(ind,1)
	for j=1:length(ind(i,2))
		switch c.frames{ind(i,1)}(ind(i,2)).tagID
		case 6	% DefineBits
			b=[table;c.frames{ind(i,1)}(ind(i,2)).tagData.JPEG];
		case 21	% DefineBitsJPEG2
			b=c.frames{ind(i,1)}(ind(i,2)).tagData.JPEG;
		case 35	% DefineBitsJPEG3
			b=c.frames{ind(i,1)}(ind(i,2)).tagData.JPEG_end_im;
		end
		if nargout
			IDs=c.frames{ind(i,1)}(ind(i,2)).tagData.ID;
			jpeg{end+1}=b;
		end
	end
end
if length(jpeg)==1
	jpeg=jpeg{1};
end

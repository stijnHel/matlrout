function ind=zoekjpegs(c)
% CSWF/ZOEKJPEGS - Zoekt jpeg's : DefineBits, -JPEG2 en -JPEG3

i0=zoektags(c,8);	% JPEGTable
i1=zoektags(c,6);	% JPEG-images
i2=zoektags(c,21);	% JPEG2
i3=zoektags(c,35);	% JPEG3

ind=[zeros(size(i0,1),1) i0;ones(size(i1,1),1) i1;zeros(size(i2,1),1)+2 i2;zeros(size(i3,1),1)+3 i3];

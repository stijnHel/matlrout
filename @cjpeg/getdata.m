function d=getdata(c,nr)% CJPEG/GETDATA - Geeft data-blok van JPEG-data%    d=getdata(c,nr)if isscalar(nr)	d=c.data(nr).data;else	d={c.data(nr).data};end
function x=uint64(c)
%lvtime/uint64 - converts to 64-bit values (to save data)

x=typecast(uint32(c.t),'uint64');

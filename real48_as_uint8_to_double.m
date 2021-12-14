function y = real48_as_uint8_to_double(x)
%REAL48_AS_UINT8_TO_DOUBLE Convert Borland 6 byte reals (Real48) to doubles.
%
%   REAL48_AS_UINT8_TO_DOUBLE(X), where X is an N-by-6 matrix of integers
%   values in the set {0,1,...,255} (uint8 values), returns an N-by-1 vector
%   of doubles.  Each row vector in X is converted into one double.
%
%   REAL48_AS_UINT8_TO_DOUBLE(X), where X is an N-by-6-by-M-by-... array
%   returns an N-by-1-by-M-by-... array of doubles.
%
%   For example, to read N Real48 values from a file identifier FID and
%   convert them to doubles, one can use
%
%      u8 = fread(fid, [6 n], 'uint8').';   % read bytes into n-by-6 array
%      y = real48_as_uint8_to_double(u8);   % convert to double
%
%   Note: Bytes are assumed to be in "big-endian" byte order.  If the data
%   are in "little-endian" ("VAX") byte order, reverse the byte order by
%   flipping the data along the second dimension with FLIPDIM(X, 2).
%
%   See also HEX2NUM.

%   The real48 consists of 6 bytes or 48 bits with field sizes 1-39-8 for
%   sign, fraction part, and biased exponent, respectively.  The sign bit is 0
%   for positive, 1 for negative.  The first bit of the floating part field is
%   assumed to be 1 and is not stored explicitly.  The exponent field is 129
%   plus the actual exponent.  Thus, if s, f, and e are the sign, floating
%   part, and biased exponent, respectively, the value represented is
%
%      s = 0:       (1 + f) * 2 ^ (e - 129)
%      s = 1:      -(1 + f) * 2 ^ (e - 129)
%
%   An exception is zero, which is represented by both f and e being zero.

%   This program is based on a program rpascal.m written by Kelley
%   Mascher <mascher@u.washington.edu>.

%   Author:      Peter J. Acklam
%   Time-stamp:  2002-03-03 13:50:13 +0100
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam

   % check number of input arguments
   error(nargchk(1, 1, nargin));

   % see if the input array has the right number of columns
   sx = size(x);
   if sx(2) ~= 6
      error('Input array must have 6 columns.');
   end

   % compute the size of the output array
   sy = sx;
   sy(2) = sy(2)/6;

   % extract the sign
   s = logical(bitget(x(:,1,:), 8));

   % extract the fraction part
   f = ((((   double(x(:,5,:))/256  ...
            + double(x(:,4,:)))/256 ...
            + double(x(:,3,:)))/256 ...
            + double(x(:,2,:)))/256 ...
            + double(bitand(x(:,1,:), 127)))/128;

   % extract the exponent
   e = double(x(:,6,:));

   % compute floating point value
   y = pow2(1+f, e-129);

   % zeros are a special case
   y(f == 0 & e == 0) = 0;

   y(s) = -y(s);
   y = reshape(y, sy);


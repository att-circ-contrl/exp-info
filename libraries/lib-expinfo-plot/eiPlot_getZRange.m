function zrange = eiPlot_getZRange( infodata, infofield, method )

% function zrange = eiPlot_getZRange( infodata, infofield, method )
%
% This gets the data range limits within a TIMEWINLAGDATA.txt structure,
% ignoring self-comparisons.
%
% "infodata" is a data structure with pairwise information as a function of
%   time and delay, per TIMEWINLAGDATA.txt.
% "infofield" is the field name within "infodata" that contains data to
%   get the range of (e.g. 'xcorrsingle', 'mutualavg', etc).
% "method" is 'symm' for symmetrical positive and negative limits, or
%   'asymm' for separate positive and negative limits. If this parameter is
%   omitted or empty, it defaults to 'symm'.
%
% "zrange" [ min max ] is the data range.


zrange = [ -1 1 ];

epsilon = 1e-6;


if ~exist('method', 'var')
  method = 'symm';
elseif isempty(method)
  method = 'symm';
end

want_symm = ~ contains( method, 'asymm' );


% Test both permutations of pairs of channels, but omit self-comparisons.
validmask = ~ nlUtil_getSelfMask( infodata.destchans, infodata.srcchans );

maxval = -inf;
minval = inf;

for dstidx = 1:length(infodata.destchans)
  for srcidx = 1:length(infodata.srcchans)
    if validmask(dstidx,srcidx)

      thisslice = infodata.(infofield)(dstidx,srcidx,:,:);
      thisslice = reshape( thisslice, 1, [] );

      maxval = max( maxval, max(thisslice) );
      minval = min( minval, min(thisslice) );

    end
  end
end


if isfinite(maxval) && isfinite(minval)
  if want_symm
    maxabs = max( abs(maxval), abs(minval) );
    maxval = maxabs;
    minval = -maxabs;
  end

  if (maxval - minval) < epsilon
    maxval = maxval + epsilon;
    minval = minval - epsilon;
  end

  zrange = [ minval maxval ];
end



% Done.
end


%
% This is the end of the file.

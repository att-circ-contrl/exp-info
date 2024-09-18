function newdata = eiAux_squashZeroLagPairs( olddata, infofield, ...
  lagwindow_ms, peakthresh, squashval, squashfields, squashall )

% function newdata = eiAux_squashZeroLagPairs( olddata, infofield, ...
%   lagwindow_ms, peakthresh, squashval, squashfields, squashall )
%
% This squashes pairwise information values that have a peak near zero lag.
% This indicates a strong common component, either from noise or from
% electrical coupling between channels.
%
% "olddata" is a pairwise information data structure per TIMEWINLAGDATA.txt.
% "infofield" is the field to look at within "olddata" (e.g. 'xcorrsingle').
% "lagwindow_ms" [ min max ] is the range of lag values to consider when
%   looking for a spurious peak.
% "peakthresh" is the factor by which the peak value within-window must
%   exceed the peak value out-of-window for the in-window component to be
%   considered "bad".
% "squashval" is the value to replace bad data with.
% "squashfields" is a cell array with the field names of data matrices to
%   write squashed values to (e.g. 'xcorrsingle', 'mutualavg').
% "squashall" is true to squash all information values for the affected
%   channel pair, or false to only squash values in the specified lag window.
%
% "newdata" is a copy of "olddata" with "bad" data squashed.


newdata = olddata;


dstlabels = newdata.destchans;
srclabels = newdata.srcchans;

squashfields = squashfields( contains(squashfields, fieldnames(newdata)) );

lagmask = (newdata.delaylist_ms >= min(lagwindow_ms)) ...
  & (newdata.delaylist_ms <= max(lagwindow_ms));


for dstidx = 1:length(dstlabels)
  for srcidx = 1:length(srclabels)

    thisslice = newdata.(infofield)(dstidx,srcidx,:,:);

    zeroslice = thisslice(1,1,:,lagmask);
    nonzeroslice = thisslice(1,1,:,~lagmask);

    zeromax = max( abs(zeroslice), [], 'all' );
    zeromean = mean( abs(zeroslice), 'all' );

    nonzeromax = max( abs(nonzeroslice), [], 'all' );

    % NOTE - Switching to mean zero-lag, from max zero-lag.
%    if zeromax >= (peakthresh * nonzeromax)
    if zeromean >= (peakthresh * nonzeromax)
      if squashall
        thisslice(1,1,:,:) = squashval;
      else
        thisslice(1,1,:,lagmask) = squashval;
      end

      newdata.(infofield)(dstidx,srcidx,:,:) = thisslice;
    end

  end
end


% Done.
end


%
% This is the end of the file.

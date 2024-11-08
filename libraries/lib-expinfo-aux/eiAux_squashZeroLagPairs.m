function newdata = eiAux_squashZeroLagPairs( olddata, infofield, ...
  lagwindow_ms, peakthresh, squashdata, squashvar, squashall )

% function newdata = eiAux_squashZeroLagPairs( olddata, infofield, ...
%   lagwindow_ms, peakthresh, squashdata, squashvar, squashall )
%
% This squashes pairwise information values that have a peak near zero lag.
% This indicates a strong common component, either from noise or from
% electrical coupling between channels.
%
% "olddata" is a pairwise information data structure per TIMEWINLAGDATA.txt.
% "infofield" is a character vector with the prefix of the data field being
%   operated on. For prefix "FOO", the fields "FOOdata", "FOOcount",
%   and "FOOvar" are expected to exist.
% "lagwindow_ms" [ min max ] is the range of lag values to consider when
%   looking for a spurious peak.
% "peakthresh" is the factor by which the mean value within-window must
%   exceed the peak value out-of-window for the in-window component to be
%   considered "bad".
% "squashdata" is the value to replace bad data values with.
% "squashvar" is the value to replace bad data's variance values with.
% "squashall" is true to squash all information values for the affected
%   channel pair, or false to only squash values in the specified lag window.
%
% "newdata" is a copy of "olddata" with "bad" data squashed.


newdata = olddata;


% Fetch the specified data field and bail out if we can't find it.

if (~isfield( olddata, [ infofield 'data' ] )) ...
  || (~isfield( olddata, [ infofield 'count' ] )) ...
  || (~isfield( olddata, [ infofield 'var' ] ))
  disp([ '### [eiAux_squashZeroLagPairs]  Can''t find field "' ...
    infofield '".' ]);
end


% Get metadata.

dstlabels = newdata.destchans;
srclabels = newdata.srcchans;

datafield = [ infofield 'data' ];
varfield = [ infofield 'var' ];
testdata = newdata.(datafield);

trialcount = size(testdata,3);

lagmask = (newdata.delaylist_ms >= min(lagwindow_ms)) ...
  & (newdata.delaylist_ms <= max(lagwindow_ms));


% Walk through trials, squashing ones that fail the test.

for dstidx = 1:length(dstlabels)
  for srcidx = 1:length(srclabels)
    for tidx = 1:trialcount

      thisslice = testdata(dstidx,srcidx,tidx,:,:);

      zeroslice = thisslice(1,1,1,:,lagmask);
      nonzeroslice = thisslice(1,1,1,:,~lagmask);

      zeromax = max( abs(zeroslice), [], 'all' );
      zeromean = mean( abs(zeroslice), 'all' );

      nonzeromax = max( abs(nonzeroslice), [], 'all' );

      % FIXME - Switching to mean zero-lag, from max zero-lag.
      % Already updated documentation above.
%      if zeromax >= (peakthresh * nonzeromax)
      if zeromean >= (peakthresh * nonzeromax)
        if squashall
          newdata.(datafield)(dstidx,srcidx,tidx,:,:) = squashdata;
          newdata.(varfield)(dstidx,srcidx,tidx,:,:) = squashvar;
        else
          newdata.(datafield)(dstidx,srcidx,tidx,:,lagmask) = squashdata;
          newdata.(varfield)(dstidx,srcidx,tidx,:,lagmask) = squashvar;
        end
      end

    end
  end
end


% Done.
end


%
% This is the end of the file.

function newdata = eiCalc_smoothTimeLagAverages( ...
  olddata, datafields, timesmooth_ms, lagsmooth_ms, method )

% function newdata = eiCalc_smoothTimeLagAverages( ...
%   olddata, datafields, timesmooth_ms, lagsmooth_ms, method )
%
% This function smooths time-and-lag analysis data and optionally re-bins it
% using coarser bins.
%
% This can operate on both aggregate and per-trial data fields.
%
% "olddata" is a data structure per TIMEWINLAGDATA.txt.
% "datafields" is a cell array containing the field names in "olddata" to
%   operate on. For each field name "FOO", if "FOOdata", "FOOvar", and
%   "FOOcount" exist, they're used. Otherwise, "FOO" itself is used.
% "timesmooth_ms" is the smoothing/binning window size for window times, in
%   milliseconds. Specify NaN to not smooth window times.
% "lagsmooth_ms" is the smoothing/binning window size for correlation time
%   lags, in milliseconds. Specify NaN to not smooth lags.
% "method" is 'smooth' to perform smoothing and keep the same bins, or
%   'coarse' to re-bin into larger bins.
%
% "newdata" is a data structure per TIMEWINLAGDATA.txt containing data from
%   the requested fields that's either smoothed or re-binned. Metadata is
%   copied from "olddata", with delay and window lists modified if re-binning
%   was performed.


%
% Initialize.

newdata = struct();
newdata.destchans = olddata.destchans;
newdata.srcchans = olddata.srcchans;
newdata.trialnums = olddata.trialnums;


%
% Get metadata.

want_decimate = strcmp(method, 'coarse');

destcount = length(olddata.destchans);
srccount = length(olddata.srcchans);

delaylist_ms = olddata.delaylist_ms;
windowlist_ms = olddata.windowlist_ms;

delaycount = length(delaylist_ms);
windowcount = length(windowlist_ms);


%
% Figure out our bin mappings.

% This has to tolerate nonuniform bins.

[ delaysources delaylist_new ] = ...
  helper_mapBins( delaylist_ms, lagsmooth_ms, want_decimate );
[ windowsources windowlist_new ] = ...
  helper_mapBins( windowlist_ms, timesmooth_ms, want_decimate );


%
% Store modified bin metadata.

newdata.delaylist_ms = delaylist_new;
newdata.windowlist_ms = windowlist_new;

% NOTE - Not adjusting window size!
newdata.windowsize_ms = olddata.windowsize_ms;

newdelaycount = length(delaylist_new);
newwindowcount = length(windowlist_new);


%
% Figure out which fields are data/var/count tuples and which aren't.

scratchfields = datafields;
datafields = {};
have_tuple = false([]);
trial_counts = [];

for fidx = 1:length(scratchfields)
  thisfield = scratchfields{fidx};

  if isfield( olddata, [ thisfield 'data' ] ) ...
    && isfield( olddata, [ thisfield 'var' ] ) ...
    && isfield( olddata, [ thisfield 'count' ] )

    scratch = olddata.([ thisfield 'data' ]);

    have_tuple = [ have_tuple true ];
    trial_counts = [ trial_counts size(scratch, 3) ];

    datafields = [ datafields { thisfield } ];

  elseif isfield( olddata, thisfield )

    scratch = olddata.(thisfield);

    % FIXME - Blithely assume that all per-trial data will be 5-dimensional.
    % If the user tests with a single time lag, that won't be the case.

    if 5 == ndims(scratch)
      have_tuple = [ have_tuple false ];
      trial_counts = [ trial_counts size(scratch, 3) ];

      datafields = [ datafields { thisfield } ];
    end

  else
    disp([ '### [eiCalc_smoothTimeLagAverages]  Can''t find field "' ...
      thisfield '".' ]);
  end
end



%
% Build the new data arrays.

for fidx = 1:length(datafields)

  thisfield = datafields{fidx};

  newavg = zeros([ destcount srccount ...
    trial_counts(fidx) newwindowcount newdelaycount ]);

  newvar = zeros(size(newavg));
  newcount = zeros(size(newavg));

  for didxnew = 1:newdelaycount
    for widxnew = 1:newwindowcount

      thisdelaysrclist = delaysources{didxnew};
      thiswindowsrclist = windowsources{widxnew};

      if have_tuple(fidx)
        [ thisavg thisvar thiscount ] = helper_averageWithStats( ...
          olddata, thisfield, thisdelaysrclist, thiswindowsrclist );
      else
        [ thisavg thisvar thiscount ] = helper_averageBlind( ...
          olddata, thisfield, thisdelaysrclist, thiswindowsrclist );
      end

      newavg(:,:,:,widxnew,didxnew) = thisavg;
      newvar(:,:,:,widxnew,didxnew) = thisvar;
      newcount(:,:,:,widxnew,didxnew) = thiscount;

    end
  end

  newdata.([ thisfield 'data' ]) = newavg;
  newdata.([ thisfield 'count' ]) = newcount;
  newdata.([ thisfield 'var' ]) = newvar;

end


% Done.
end



%
% Helper Functions


% This identifies which old bins contribute to each new bin.
% This also lists centres of new bins, to account for decimation.
% A smoothing window of NaN means "don't smooth/decimate".

function [ mapsources newlist ] = ...
  helper_mapBins( oldlist, smoothwindow, want_decimate )

  if isnan(smoothwindow)
    mapsources = 1:length(oldlist);
    mapsources = num2cell(mapsources);
    newlist = oldlist;
  else
    % Do this by brute force. O(n2) is fine here.

    mapsources = {};
    newlist = [];

    % Trim or pad these by a small amount to avoid precision issues.
    smoothradius = 0.51 * smoothwindow;
    decimstep = 0.99 * smoothwindow;

    lastnew = -inf;

    for oldidx = 1:length(oldlist)

      thispos = oldlist(oldidx);

      wantkeep = true;
      if want_decimate
        wantkeep = ( (thispos - lastnew) >= decimstep );
      end

      if wantkeep
        lastnew = thispos;

        minval = thispos - smoothradius;
        maxval = thispos + smoothradius;

        thismap = find( (oldlist >= minval) & (oldlist <= maxval) );

        mapsources = [ mapsources { thismap } ];
        newlist = [ newlist thispos ];
      end

    end
  end

end



% This fetches "FOOdata", "FOOvar", and "FOOcount" within a region and
% produces average/variance/count values derived from these.

function [ thisavg thisvar thiscount ] = helper_averageWithStats( ...
  olddata, thisfield, thisdelaysrclist, thiswindowsrclist )

  fielddata = olddata.([ thisfield 'data' ]);
  fieldcount = olddata.([ thisfield 'count' ]);
  fieldvar = olddata.([ thisfield 'var' ]);

  destcount = length(olddata.destchans);
  srccount = length(olddata.srcchans);
  trialcount = size(fielddata, 3);

  thisavg = zeros([ destcount srccount trialcount ]);
  thisvar = zeros(size(thisavg));
  thiscount = zeros(size(thisavg));

  for didxsrc = 1:length(thisdelaysrclist)
    for widxsrc = 1:length(thiswindowsrclist)

      didxold = thisdelaysrclist(didxsrc);
      widxold = thiswindowsrclist(widxsrc);

      % These are (destidx,srcidx,tidx) matrices, not scalars.

      olddata = fielddata(:,:,:,widxold,didxold);
      oldcount = fieldcount(:,:,:,widxold,didxold);
      oldvar = fieldvar(:,:,:,widxold,didxold);

      validmask = (~isnan(olddata)) & (oldcount > 0);

      thisavg(validmask) = thisavg(validmask) ...
        + ( olddata(validmask) .* oldcount(validmask) );
      thisvar(validmask) = thisvar(validmask) ...
        + ( oldvar(validmask) .* oldcount(validmask) );
      thiscount(validmask) = thiscount(validmask) + oldcount(validmask);

    end
  end

  % Anything with a count of 0 gets turned into NaN, which is fine.
  thisavg = thisavg ./ thiscount;
  thisvar = thisvar ./ thiscount;

end



% This fetches raw data values within a region and produces
% average/variance/count values derived from them.

function [ thisavg thisvar thiscount ] = helper_averageBlind( ...
  olddata, thisfield, thisdelaysrclist, thiswindowsrclist )

  fielddata = olddata.(thisfield);

  destcount = length(olddata.destchans);
  srccount = length(olddata.srcchans);
  trialcount = size(fielddata, 3);

  thisavg = zeros([ destcount srccount trialcount ]);
  thisvar = zeros(size(thisavg));
  thiscount = zeros(size(thisavg));


  % First pass: Get average and count.

  for didxsrc = 1:length(thisdelaysrclist)
    for widxsrc = 1:length(thiswindowsrclist)

      didxold = thisdelaysrclist(didxsrc);
      widxold = thiswindowsrclist(widxsrc);

      % These are (destidx,srcidx,tidx) matrices, not scalars.

      olddata = fielddata(:,:,:,widxold,didxold);

      validmask = (~isnan(olddata));

      thisavg(validmask) = thisavg(validmask) + olddata(validmask);
      thiscount = thiscount + validmask;

    end
  end

  % Anything with a count of 0 gets turned into NaN, which is fine.
  thisavg = thisavg ./ thiscount;


  % Second pass: Get the variance.

  for didxsrc = 1:length(thisdelaysrclist)
    for widxsrc = 1:length(thiswindowsrclist)

      didxold = thisdelaysrclist(didxsrc);
      widxold = thiswindowsrclist(widxsrc);

      % These are (destidx,srcidx,tidx) matrices, not scalars.

      olddata = fielddata(:,:,:,widxold,didxold);

      validmask = (~isnan(olddata));

      % Anything that comes from one sample has olddata = thisavg, and a
      % variance of 0. This is fine.
      olddata = olddata - thisavg;
      olddata = olddata .* olddata;
      thisvar(validmask) = thisvar(validmask) + olddata(validmask);

    end
  end

  % Anything with a count of 0 gets turned into NaN, which is fine.
  thisvar = thisvar ./ thiscount;

end


%
% This is the end of the file.

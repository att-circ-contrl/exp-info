function [ ampmean ampdev lagmean lagdev ] = ...
  eiCalc_getTimeLagPeakStats( timelagdata, datafield, ...
    timerange_ms, timesmooth_ms, magthresh, magacceptrange, method )

% function [ ampmean ampdev lagmean lagdev ] = ...
%   eiCalc_getTimeLagPeakStats( timelagdata, datafield, ...
%     timerange_ms, timesmooth_ms, magthresh, magacceptrange, method )
%
% This analyzes a time-and-lag analysis dataset, extracting the mean and
% deviation of the data peak's amplitude and time lag by black magic,
% within the analysis window time range specified.
%
% This calls eiCalc_collapseTimeLagAverages() to get the mean and deviation
% of the amplitude, finds the peak closest to 0 lag, finds the extent of
% that peak (via thresholding), and then calls eiCalc_findTimeLagPeaks() to
% get peak amplitude and lag as a function of time. This is masked to reject
% peaks too far from the average peak's amplitude and lag extent, and then
% statistics are extracted.
%
% This works if and only if there _is_ a fairly clean data peak.
% Smoothing ahead of time might be necessary, and the target ranges will
% probably need to be hand-tuned.
%
% "timelagdata" is a data structure per TIMEWINLAGDATA.txt.
% "datafield" is a character vector with the prefix of the field being
%   operated on. For prefix "FOO", the fields "FOOdata", "FOOcount",
%   and "FOOvar" are expected to exist.
% "timerange_ms" [ min max ] specifies a window time range in milliseconds
%   to examine. A range of [] indicates all window times.
% "timesmooth_ms" is the smoothing window size in milliseconds for smoothing
%   data along the time axis before performing time-varying peak detection.
%   Specify 0 or NaN to not smooth.
% "magthresh" is a scalar between 0 and 1 specifying the data magnitude
%   cutoff used for finding peak extents. The extent threshold is this value
%   times the peak magnitude. A value of 0 is typical.
% "magacceptrange" [ min max ] is two positive scalar values that are
%   multiplied by the peak data magnitude to get a data magnitude acceptance
%   range for time-varying peak detection. A typical range would be
%   [ 0.5 inf ].
% "method" is an optional argument. If present, it should be 'largest' or
%   'weighted', specifying an eiCalc_findTimeLagPeaks search method. The
%   default is 'largest'.
%
% "ampmean" is a matrix indexed by (destidx,srcidx,trialidx) containing the
%   mean (signed) peak data value within the specified window for each pair.
% "ampdev" is a matrix indexed by (destidx,srcidx,trialidx) containing the
%   standard deviation of the peak data value for each pair.
% "lagmean" is a matrix indexed by (destidx,srcidx,trialidx) containing the
%   mean time lag within the specified window for each pair.
% "lagdev" is a matrix indexed by (destidx,srcidx,trialidx) containing the
%   standard deviation of the time lag for each pair.


% Get metadata.

destchans = timelagdata.destchans;
destcount = length(destchans);

srcchans = timelagdata.srcchans;
srccount = length(srcchans);

laglist = timelagdata.delaylist_ms;
lagcount = length(laglist);

winlist = timelagdata.windowlist_ms;
wincount = length(winlist);

if isempty(timerange_ms)
  timerange_ms = [ -inf, inf ];
end

if ~exist('method', 'var')
  method = 'largest';
end


% Set placeholder return values in case we bail out.
ampmean = [];
ampdev = [];
lagmean = [];
lagdev = [];


% Fetch the specified data field.

if (~isfield( timelagdata, [ datafield 'data' ] )) ...
  || (~isfield( timelagdata, [ datafield 'count' ] )) ...
  || (~isfield( timelagdata, [ datafield 'var' ] )) ...
  disp([ '### [eiCalc_getTimeLagPeakStats]  Can''t find field "' ...
    datafield '".' ]);
  return;
end

datavals = timelagdata.([ datafield 'data' ]);
countvals = timelagdata.([ datafield 'count' ]);
varvals = timelagdata.([ datafield 'var' ]);


% Get the actual trial count for this field; it might be a trial-spanning
% average.

trialcount = size(datavals,3);


% Initialize output.

scratch = NaN([ destcount srccount trialcount ]);

ampmean = scratch;
ampdev = scratch;
lagmean = scratch;
lagdev = scratch;


%
% First pass: Do peak detection on the average (not time-varying).

[ avgvstime avgvslag ] = eiCalc_collapseTimeLagAverages( ...
  timelagdata, datafield, { timerange_ms }, [] );

scratch = NaN([ destcount srccount trialcount ]);

guessamp = scratch;
guesslagmin = scratch;
guesslagmax = scratch;

for destidx = 1:destcount
  for srcidx = 1:srccount
    for tidx = 1:trialcount

      thisdata = avgvslag.avg(destidx,srcidx,tidx,:);
      thisdata = reshape(thisdata, size(laglist));

      % Find the peak in average magnitude vs lag.
      bestidx = nlProc_findPeakNearest( thisdata, laglist, 0 );

      if ~isnan(bestidx)
        % Threshold around the peak to get the accepted lag range.
        % Note that "thisdata" and "thisamp" are both signed; the division
        % makes "normamp" positive no matter what the peak's sign was.

        thisamp = thisdata(bestidx);
        normamp = thisdata / thisamp;
        ampmask = normamp >= magthresh;

        thislagmin = laglist(bestidx);
        thislagmax = laglist(bestidx);

        % There's probably a Matlab way to do this, but do it by hand.

        inpeak = true;
        for lidx = bestidx:lagcount
          inpeak = inpeak & ampmask(lidx);
          if inpeak
            thislagmin = min(thislagmin, laglist(lidx));
            thislagmax = max(thislagmax, laglist(lidx));
          end
        end

        inpeak = true;
        for lidx = bestidx:-1:1
          inpeak = inpeak & ampmask(lidx);
          if inpeak
            thislagmin = min(thislagmin, laglist(lidx));
            thislagmax = max(thislagmax, laglist(lidx));
          end
        end

        % Save these.
        guessamp(destidx,srcidx,tidx) = thisamp;
        guesslagmin(destidx,srcidx,tidx) = thislagmin;
        guesslagmax(destidx,srcidx,tidx) = thislagmax;
      end

    end
  end
end



%
% Second pass: Get time-varying peak detection statistics.

timemask = (winlist >= min(timerange_ms)) & (winlist <= max(timerange_ms));

for destidx = 1:destcount
  for srcidx = 1:srccount
    for tidx = 1:trialcount

      lagrange = ...
        [ guesslagmin(destidx,srcidx,tidx), guesslagmax(destidx,srcidx,tidx) ];
      amprange = magacceptrange * guessamp(destidx,srcidx,tidx);


      % Extract just this pair and call the search function.
      % We can't call the search function globally because the lag range
      % varies by pair and by trial.

      thispairdata = struct();
      thispairdata.destchans = destchans(destidx);
      thispairdata.srcchans = srcchans(srcidx);
      thispairdata.delaylist_ms = laglist;
      thispairdata.windowlist_ms = winlist;
      thispairdata.trialnums = NaN;

      thispairdata.([ datafield 'data' ]) = ...
        datavals(destidx,srcidx,tidx,:,:);
      thispairdata.([ datafield 'count' ]) = ...
        countvals(destidx,srcidx,tidx,:,:);
      thispairdata.([ datafield 'var' ]) = ...
        varvals(destidx,srcidx,tidx,:,:);

      peakdata = eiCalc_findTimeLagPeaks( ...
        thispairdata, datafield, timesmooth_ms, lagrange, method );


      % Mask the search data and compute statistics.

      thislagdata = reshape( peakdata.peaklags, size(winlist) );
      thisampdata = reshape( peakdata.peakamps, size(winlist) );

      ampmask = ...
        (thisampdata >= min(amprange)) & (thisampdata <= max(amprange));

      thislagdata = thislagdata(ampmask & timemask);
      thisampdata = thisampdata(ampmask & timemask);

      if ~isempty(thislagdata)
        ampmean(destidx,srcidx,tidx) = mean(thisampdata);
        ampdev(destidx,srcidx,tidx) = std(thisampdata);
        lagmean(destidx,srcidx,tidx) = mean(thislagdata);
        lagdev(destidx,srcidx,tidx) = std(thislagdata);
      end

    end
  end
end



% Done.
end


%
% This is the end of the file.

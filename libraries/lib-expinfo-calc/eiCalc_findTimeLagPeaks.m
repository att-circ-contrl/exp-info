function peakdata = eiCalc_findTimeLagPeaks( ...
  timelagdata, datafield, timesmooth_ms, lagtarget_ms, method )

% function peakdata = eiCalc_findTimeLagPeaks( ...
%   timelagdata, datafield, timesmooth_ms, lagtarget_ms, method )
%
% This examines time-and-lag analysis data and attempts to find the time lag
% with the peak data value for each window time. The intention is to be
% able to track the peak's location and amplitude for each signal pair as
% the signals evolve with time.
%
% Peaks are local maxima of magnitude (ignoring sign and complex phase angle).
%
% NOTE - Peak detection is sensitive to the structure of the data. Smoothing
% ahead of time will produce more reliable results, and the target range
% will probably need to be hand-tuned.
%
% "timelagdata" is a data structure per TIMEWINLAGDATA.txt.
% "datafield" is a character vector with the prefix of the data field
%   being operated on. For prefix "FOO", the fields "FOOdata", "FOOcount",
%   and "FOOvar" are expected to exist.
% "timesmooth_ms" is the window size for smoothing data along the window
%   time axis, in milliseconds. Specify 0 or NaN to not smooth.
% "lagtarget_ms" is a [ min max ] range for accepted time lags if using the
%   'largest' or 'weighted' search methods, or a scalar specifying the search
%   starting point if using the 'nearest' method.
% "method" is 'largest' to find the highest-magnitude peak in range (use
%   [] for the full range), or 'nearest' to find the peak closest to the
%   specified starting point, or 'weighted' to find the highest-magnitude
%   peak in range after weighting by a roll-off window.
%
% "peakdata" is a struct containing detected peak information, per
%   TIMEWINLAGPEAKS.txt.


% Get metadata.

destcount = length(timelagdata.destchans);
srccount = length(timelagdata.srcchans);

timelist_ms = timelagdata.windowlist_ms;
laglist_ms = timelagdata.delaylist_ms;

trialnums = timewinlagdata.trialnums;

lagcount = length(timelagdata.delaylist_ms);
wincount = length(timelagdata.windowlist_ms);


% Set a placeholder return value in case we bail out.
peakdata = struct();


% Fetch the specified data field.

if (~isfield( timelagdata, [ datafield 'data' ] )) ...
  || (~isfield( timelagdata, [ datafield 'count' ] )) ...
  || (~isfield( timelagdata, [ datafield 'var' ] ))
  disp([ '### [eiCalc_findTimeLagPeaks]  Can''t find field "' ...
    datafield '".' ]);
  return;
end

datavals = timelagdata.([ datafield 'data' ]);
countvals = timelagdata.([ datafield 'count' ]);
varvals = timelagdata.([ datafield 'var' ]);


% Get the actual trial count for this field; it might be a trial-spanning
% average. If so, update "trialnums".

trialcount = size(datavals,3);

if length(trialnums) > trialcount
  trialnums = NaN;
end


%
% Initialize output and copy metadata.

peakdata = struct();

peakdata.destchans = timelagdata.destchans;
peakdata.srcchans = timelagdata.srcchans;
peakdata.windowlist_ms = timelagdata.windowlist_ms;
peakdata.trialnums = trialnums;

scratch = nan([ destcount srccount trialcount wincount ]);
peakdata.peaklags = scratch;
peakdata.peakamps = scratch;
peakdata.peakcounts = scratch;
peakdata.peakvars = scratch;


%
% First pass: Perform smoothing if requested.

if (~isnan(timesmooth_ms)) && (timesmooth_ms > 0)
  % Assume mostly-uniform spacing.
  timestep_ms = median(diff( timelist_ms ));
  smoothsize = round(timesmooth_ms / timestep_ms);

  if smoothsize > 1

    for destidx = 1:destcount
      for srcidx = 1:srccount
        for tidx = 1:trialcount
          for lagidx = 1:lagcount
            thisdata = datavals(destidx, srcidx, tidx, :, lagidx);
            thisdata = reshape(thisdata, size(timelist_ms));

            % Triangular smoothing window with about 1.5x the requested size.
            thisdata = movmean(thisdata, smoothsize);
            thisdata = movmean(thisdata, smoothsize);

            datavals(destidx, srcidx, tidx, :, lagidx) = thisdata;
          end
        end
      end
    end

  end
end



%
% Second pass: Perform peak detection.


% Peak detection mask, if desired.

lagmask = true(size(laglist_ms));
startidx = NaN;

if ( strcmp('largest', method) || strcmp('weighted', method) ) ...
  && (~isempty(lagtarget_ms))
  minlag = min(lagtarget_ms);
  maxlag = max(lagtarget_ms);
  lagmask = (laglist_ms >= minlag) & (laglist_ms <= maxlag);
elseif strcmp('nearest', method')
  % Tolerate poorly formed input.
  if isnan(lagtarget_ms) || isempty(lagtarget_ms)
    lagtarget_ms = 0;
  end
  lagtarget_ms = median(lagtarget_ms);
end


% Peak detection weighting window, if desired.

% This tolerates asking for 0 elements.
lagwindow = linspace(-1, 1, sum(lagmask));
% Use a circular rolloff window.
lagwindow = sqrt(1 - lagwindow .* lagwindow);

% Make sure geometry matches.
if isrow(lagmask) ~= isrow(lagwindow)
  lagwindow = transpose(lagwindow);
end

% Make this a top-hat window if we aren't doing weighting.
if ~strcmp('weighted', method)
  lagwindow = ones(size(lagwindow));
end


for destidx = 1:destcount
  for srcidx = 1:srccount
    for tidx = 1:trialcount
      for winidx = 1:wincount

        thisdata = datavals(destidx, srcidx, tidx, winidx, :);
        thiscount = countvals(destidx, srcidx, tidx, winidx, :);
        thisvar = varvals(destidx, srcidx, tidx, winidx, :);

        % Make sure the data and the lag list have the same geometry.

        thisdata = reshape(thisdata, size(laglist_ms));
        thiscount = reshape(thiscount, size(laglist_ms));
        thisvar = reshape(thisvar, size(laglist_ms));


        % Mask to only consider the desired lag range.

        thisdata = thisdata(lagmask);
        thiscount = thiscount(lagmask);
        thisvar = thisvar(lagmask);

        thislag = laglist_ms(lagmask);


        % Initialize output.

        thispeaklag = NaN;
        thispeakamp = NaN;
        thispeakcount = NaN;
        thispeakvar = NaN;


        % Find where this peak is, if we can. We might get NaN.

        bestidx = NaN;
        if strcmp('largest', method) || strcmp('weighted', method)
          bestidx = ...
            nlProc_findPeakLargest( thisdata .* lagwindow );
        elseif strcmp('nearest', method)
          bestidx = ...
            nlProc_findPeakNearest( thisdata, thislag, lagtarget_ms );
        end


        % Record peak data if we found one.

        if ~isnan(bestidx)
          thispeaklag = thislag(bestidx);
          thispeakamp = thisdata(bestidx);
          thispeakcount = thiscount(bestidx);
          thispeakvar = thisvar(bestidx);
        end


        % Copy the output.

        peakdata.peaklags(destidx, srcidx, tidx, winidx) = thispeaklag;
        peakdata.peakamps(destidx, srcidx, tidx, winidx) = thispeakamp;
        peakdata.peakcounts(destidx, srcidx, tidx, winidx) = thispeakcount;
        peakdata.peakvars(destidx, srcidx, tidx, winidx) = thispeakvar;

      end
    end
  end
end



% Done.
end


%
% This is the end of the file.

function winlagdata = eiCalc_doTimeAndLagAnalysis( ...
  ftdata_dest, ftdata_src, winlagparams, flags, ...
  analysis_preproc, analysis_func, analysis_params, ...
  filter_preproc, filter_func, filter_params )

% function winlagdata = eiCalc_doTimeAndLagAnalysis( ...
%   ftdata_dest, ftdata_src, winlagparams, flags, ...
%   analysis_preproc, analysis_func, analysis_params, ...
%   filter_preproc, filter_func, filter_params )
%
% This compares two Field Trip datasets within a series of time windows,
% calculating some measure such as cross-correlation or transfer entropy
% that is evaluated for several time lags.
%
% Results may be stored per trial, or averaged across trials, or both.
%
% For each trial and time window, a filter function is applied to determine
% whether that window of that trial is accepted. Windows that are rejected
% have NaN stored in per-trial data and do not contribute to the average
% across trials.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% "ftdata_dest" is a ft_datatype_raw structure with trial data for the
%   putative destination channels.
% "ftdata_src" is a ft_datatype_raw structure with trial data for the
%   putative source channels.
% "winlagparams" is a structure giving time window and time lag information,
%   per TIMEWINLAGSPEC.txt.
% "flags" is a cell array containing zero or more of the following character
%   vectors, per PROCFLAGS.txt:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
%   'spantrials' generates data by concatenating or otherwise aggregating
%     across trials, per TIMEWINLAGDATA.txt.
% "analysis_preproc" is a cell array containing zero or more character vectors
%   indicating what preprocessing to perform on signals sent to the analysis
%   function. Preprocessing happens before time-windowing:
%   'zeromean' subtracts the mean of each signal.
%   'detrend' detrends each signal.
%   'hilbert' generates a complex-valued analytic signal for each signal.
%   'angle' takes the instantaneous phase (in radians) of the analytic signal.
% "analysis_func" is an analysis function handle, per TIMEWINLAGFUNCS.txt.
% "analysis_params" is a tuning parameter structure to be passed to the
%   analysis function handle.
% "filter_preproc" is a cell array containing zero or more character vectors
%   indicating what preprocessing to perform on signals sent the filter
%   function. Switches are the same as with "analysis_preproc".
% "filter_func" is an acceptance filter function handle, per TIMEWINLAGFUNCS.
% "filter_params" is a tuning parameter structure to be passed to the
%   acceptance filter function handle.
%
% "winlagdata" is a structure containing aggregated analysis data, per
%   TIMEWINLAGDATA.txt.


% Initialize.
winlagdata = struct();


% Check for bail-out conditions.

if isempty(ftdata_dest.label) || isempty(ftdata_dest.time) ...
  || isempty(ftdata_src.label) || isempty(ftdata_src.time)
  return;
end


%
% Get metadata.

% Behavior.

want_avg = ismember('avgtrials', flags);
want_pertrial = ismember('pertrial', flags);
want_spantrials = ismember('spantrials', flags);


% Geometry.

trialcount = length(ftdata_dest.time);

chancount_dest = length(ftdata_dest.label);
chancount_src = length(ftdata_src.label);


% Sampling rate.

samprate = 1 / mean(diff( ftdata_dest.time{1} ));


% Delay values.

delaylist_samps = eiCalc_helper_getDelaySamps( ...
  samprate, winlagparams.delay_range_ms, winlagparams.delay_step_ms );

delaycount = length(delaylist_samps);


% Precompute window sample ranges.

wincount = length(winlagparams.timelist_ms);

winrangesdest = eiCalc_helper_getWindowSamps( samprate, ...
  winlagparams.time_window_ms, winlagparams.timelist_ms, ftdata_dest.time );
winrangessrc = eiCalc_helper_getWindowSamps( samprate, ...
  winlagparams.time_window_ms, winlagparams.timelist_ms, ftdata_src.time );


% Get field names, now that we have a syntax for querying it.
% This is described in TIMEWINLAGFUNCS.txt.
% NOTE - This returns the base field name. The actual stored data is in
% FOOdata, FOOcount, and FOOvar.

scratch = analysis_func( [], [], samprate, [], analysis_params );
resultfields = fieldnames(scratch);

% Store suffixes while we're at it.
suffixlist = { 'data', 'count', 'var' };


%
% Store metadata.

winlagdata.destchans = ftdata_dest.label;
winlagdata.srcchans = ftdata_src.label;

winlagdata.delaylist_ms = delaylist_samps * 1000 / samprate;

winlagdata.windowlist_ms = winlagparams.timelist_ms;
winlagdata.windowsize_ms = winlagparams.time_window_ms;

% FIXME - Make up trial numbers.
% The user can replace these if they have a canonical list.
winlagdata.trialnums = 1:trialcount;



%
% Perform any ahead-of-time signal processing requested.

trialdata_dest_analysis = ...
  helper_doPreProc( ftdata_dest.trial, analysis_preproc );
trialdata_src_analysis = ...
  helper_doPreProc( ftdata_src.trial, analysis_preproc );

trialdata_dest_filter = ...
  helper_doPreProc( ftdata_dest.trial, filter_preproc );
trialdata_src_filter = ...
  helper_doPreProc( ftdata_src.trial, filter_preproc );



%
% Make templates for easier initialization.

% Most things get initialized to NaN (if we don't have data to overwrite
% them with later).

% Average and deviation.
templateavg = nan([ chancount_dest chancount_src 1 wincount delaycount ]);

% Temporary output when iterating windows.
templateonewindow = ...
  nan([ chancount_dest chancount_src trialcount delaycount ]);

% Scratch variables for computing statistics.
templateonewindowavg = zeros([ chancount_dest chancount_src delaycount ]);

% Per-trial output.
templatepertrial = ...
  nan([ chancount_dest chancount_src trialcount wincount delaycount ]);

% Trial-spanning output.
templateconcat =  nan([ chancount_dest chancount_src 1 wincount delaycount ]);



%
% Initialize output.

for fidx = 1:length(resultfields)
  thisfield = resultfields{fidx};

  for sidx = 1:length(suffixlist)
    thissuffix = suffixlist{sidx};

    if want_avg
      winlagdata.([ thisfield 'avg' thissuffix ]) = templateavg;
    end

    if want_pertrial
      winlagdata.([ thisfield 'trials' thissuffix ]) = templatepertrial;
    end

    if want_spantrials
      winlagdata.([ thisfield 'concat' thissuffix ]) = templateconcat;
    end
  end
end



%
% Iterate across windows, channel pairs, and trials.

% The outer loop is window index, so that we can hold all results for a
% given window in memory (to compute the variance).

% Channels get iterated outside, and trials iterated inside.
% This lets us collapse trials for trial-spanning calculations.


for widx = 1:wincount

  % First pass: Get the raw results for this window.
  % We'll compute average and deviation in a second pass.
  % Anything that doesn't pass the filter function gets left as NaN.


  % Initialize window results.

  thiswinresults = struct();

  for fidx = 1:length(resultfields)
    thisfield = resultfields{fidx};

    for sidx = 1:length(suffixlist)
      thissuffix = suffixlist{sidx};
      thiswinresults.([ thisfield thissuffix ]) = templateonewindow;
    end
  end


  % Channel pair iteration.

  for cidxdest = 1:chancount_dest
    for cidxsrc = 1:chancount_src

      % Initialize trial matrix data for this channel pair.

      wavematrixdest = [];
      wavematrixsrc = [];


      % Trial iteration.

      for trialidx = 1:trialcount

        % Get raw data for this trial and channel pair.
        % This is going to have inefficient access patterns if we're
        % iterating trials as the inner loop, but live with it.


        % Extract this trial's data.

        thisdatadest_an = trialdata_dest_analysis{trialidx};
        thisdatasrc_an = trialdata_src_analysis{trialidx};

        thisdatadest_filt = trialdata_dest_filter{trialidx};
        thisdatasrc_filt = trialdata_src_filter{trialidx};


        % Extract time window contents.

        % NOTE - We may sometimes get NaN data in here. The relevant results
        % will also be NaN.

        windatadest_an = thisdatadest_an(:,winrangesdest{trialidx,widx});
        windatasrc_an = thisdatasrc_an(:,winrangessrc{trialidx,widx});

        windatadest_filt = thisdatadest_filt(:,winrangesdest{trialidx,widx});
        windatasrc_filt = thisdatasrc_filt(:,winrangessrc{trialidx,widx});


        % Extract this channel pair.

        wavedest_filt = windatadest_filt(cidxdest,:);
        wavesrc_filt = windatasrc_filt(cidxsrc,:);

        wavedest_an = windatadest_an(cidxdest,:);
        wavesrc_an = windatasrc_an(cidxsrc,:);


        % Proceed only if the filter accepts this data.

        filteraccept = ...
          filter_func( wavedest_filt, wavesrc_filt, samprate, filter_params );


        % Add this to the trial-spanning matrix data if it passed the filter.

        if filteraccept & want_spantrials
          % This works even for first-time row addition.
          wavematrixdest = [ wavematrixdest ; wavedest_an ];
          wavematrixsrc = [ wavematrixsrc ; wavesrc_an ];
        end


        % Continue with the average and per-trial analyses if requested.

        if filteraccept & (want_avg | want_pertrial)

          % Analyze this trial.

          thisresult = analysis_func( ...
            wavedest_an, wavesrc_an, samprate, ...
            delaylist_samps, analysis_params );


          % Store trial-averaged and per-trial results.

          for fidx = 1:length(resultfields)
            thisfield = resultfields{fidx};

            for sidx = 1:length(suffixlist)
              thissuffix = suffixlist{sidx};

              scratch = thiswinresults.([ thisfield thissuffix ]);
              scratch(cidxdest,cidxsrc,trialidx,1:delaycount) = ...
                thisresult.([ thisfield thissuffix ]);
              thiswinresults.([ thisfield thissuffix ]) = scratch;

              if want_pertrial
                scratch = winlagdata.([ thisfield 'trials' thissuffix ]);
                scratch(cidxdest,cidxsrc,trialidx,widx,1:delaycount) = ...
                  thisresult.([ thisfield thissuffix ]);
                winlagdata.([ thisfield 'trials' thissuffix ]) = scratch;
              end
            end
          end

        end


        % Finished with this trial.

      end


      % If we're spanning across trials, do that analysis here.

      if want_spantrials && (~isempty(wavematrixdest))

        thisresult = analysis_func( ...
          wavematrixdest, wavematrixsrc, samprate, ...
          delaylist_samps, analysis_params );

        for fidx = 1:length(resultfields)
          thisfield = resultfields{fidx};

          for sidx = 1:length(suffixlist)
            thissuffix = suffixlist{sidx};

            scratch = winlagdata.([ thisfield 'concat' thissuffix ]);
            scratch(cidxdest,cidxsrc,1,widx,1:delaycount) = ...
              thisresult.([ thisfield thissuffix ]);
            winlagdata.([ thisfield 'concat' thissuffix ]) = scratch;
          end
        end

      end

      % Finished with this channel pair.

    end
  end


  % Second pass: Compute average statistics, if desired.

  if want_avg
    for fidx = 1:length(resultfields)

      thisfield = resultfields{fidx};

      winavg = templateonewindowavg;
      wincount = templateonewindowavg;
      winvarint = templateonewindowavg;
      winvar = templateonewindowavg;

      thisresultdata = thiswinresults.([ thisfield 'data' ]);
      thisresultcount = thiswinresults.([ thisfield 'count' ]);
      thisresultvar = thiswinresults.([ thisfield 'var' ]);
      validmask = ~isnan(thisresultdata);


      % Get the count and the average and the within-trial variance.
      % Ignore NaN entries.

      for trialidx = 1:trialcount
        for delayidx = 1:delaycount
          thisresultdataslice = thisresultdata(:,:,trialidx,delayidx);
          thisresultcountslice = thisresultcount(:,:,trialidx,delayidx);
          thisresultvarslice = thisresultvar(:,:,trialidx,delayidx);

          thisvalid = validmask(:,:,trialidx,delayidx);

          % The averages are weighted by sample counts.

          avgslice = winavg(:,:,delayidx);
          avgslice(thisvalid) = avgslice(thisvalid) ...
      + thisresultdataslice(thisvalid) .* thisresultcountslice(thisvalid);
          winavg(:,:,delayidx) = avgslice;

          varintslice = winvarint(:,:,delayidx);
          varintslice(thisvalid) = varintslice(thisvalid) ...
      + thisresultvarslice(thisvalid) .* thisresultcountslice(thisvalid);
          winvarint(:,:,delayidx) = varintslice;

          % Tally the sample counts for computing the weighted average.

          countslice = wincount(:,:,delayidx);
          countslice(thisvalid) = countslice(thisvalid) ...
            + thisresultcountslice(thisvalid);
          wincount(:,:,delayidx) = countslice;
        end
      end

      winavg = winavg ./ wincount;
      winvarint = winvarint ./ wincount;


      % Get the between-trial variance.

      for trialidx = 1:trialcount
        for delayidx = 1:delaycount
          thisresultdataslice = thisresultdata(:,:,trialidx,delayidx);
          thisresultcountslice = thisresultcount(:,:,trialidx,delayidx);

          thisvalid = validmask(:,:,trialidx,delayidx);

          % Get (X-avg)^2.
          thisresultdataslice = thisresultdataslice - winavg(:,:,delayidx);
          thisresultdataslice = thisresultdataslice .* thisresultdataslice;

          % The average is weighted by sample count.

          varslice = winvar(:,:,delayidx);
          varslice(thisvalid) = varslice(thisvalid) ...
      + thisresultdataslice(thisvalid) .* thisresultcountslice(thisvalid);
          winvar(:,:,delayidx) = varslice;
        end
      end

      winvar = winvar ./ wincount;

      % Add the within-trial variance to get the total variance.
      winvar = winvar + winvarint;


      % Update global statistics.

      scratchavg = winlagdata.([ thisfield 'avgdata' ]);
      scratchvar = winlagdata.([ thisfield 'avgvar' ]);
      scratchcount = winlagdata.([ thisfield 'avgcount' ]);

      for delayidx = 1:delaycount
        scratchavg(:,:,1,widx,delayidx) = winavg(:,:,delayidx);
        scratchvar(:,:,1,widx,delayidx) = winvar(:,:,delayidx);
        scratchcount(:,:,1,widx,delayidx) = wincount(:,:,delayidx);
      end

      winlagdata.([ thisfield 'avgdata' ]) = scratchavg;
      winlagdata.([ thisfield 'avgvar' ]) = scratchvar;
      winlagdata.([ thisfield 'avgcount' ]) = scratchcount;

    end
  end


  % Finished with this window.

end



% Done.
end



%
% Helper Functions


function newtrials = helper_doPreProc( oldtrials, preprocflags )

  want_detrend = ismember('detrend', preprocflags);
  want_zeromean = ismember('zeromean', preprocflags);
  want_hilbert = ismember('hilbert', preprocflags);
  want_angle = ismember('angle', preprocflags);


  trialcount = length(oldtrials);
  chancount = 0;
  if ~isempty(oldtrials)
    chancount = size(oldtrials{1},1);
  end


  newtrials = oldtrials;

  for tidx = 1:trialcount
    thistrial = newtrials{tidx};

    for cidx = 1:chancount
      thiswave = thistrial(cidx,:);

      % Interpolate NaNs, so that detrending and Hilbert work.
      nanmask = isnan(thiswave);
      thiswave = nlProc_fillNaN(thiswave);

      if want_detrend
        thiswave = detrend(thiswave);
      elseif want_zeromean
        thiswave = thiswave - mean(thiswave);
      end

      if want_hilbert || want_angle
        thiswave = hilbert(thiswave);
      end

      if want_angle
        thiswave = angle(thiswave);
      end

      % Restore NaNs that we interpolated.
      thiswave(nanmask) = NaN;

      thistrial(cidx,:) = thiswave;
    end

    newtrials{tidx} = thistrial;
  end

end


%
% This is the end of the file.

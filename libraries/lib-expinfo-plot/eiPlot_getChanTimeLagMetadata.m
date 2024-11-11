function plotmeta = eiPlot_getChanTimeLagMetadata( ...
  infodata, infofield, destswanted, srcswanted, trialswanted, ztype )

% function plotmeta = eiPlot_getChanTimeLagMetadata( ...
%   infodata, infofield, destswanted, srcswanted, trialswanted, ztype )
%
% This extracts various common plotting-related metadata from a
% pairwise shared information structure.
%
% "infodata" is a data structure with pairwise shared information as a
%   function of time and delay, per TIMEWINLAGDATA.txt.
% "infofield" is the fieldname within "infodata" that contains data to be
%   plotted (e.g. 'xcorrconcatdata', 'mutualavgdata', etc).
% "destswanted" is a cell array containing destination channels to consider,
%   or {} to use all destination channels.
% "srcswanted" is a cell array containing source channels to consider, or
%   {} to use all source channels.
% "trialswanted" is a vector containing trial numbers (from "trialnums") to
%   consider, or [] to use all trials. NOTE - This is used to build the trial
%   mask, but is ignored when computing Z range (all trials are considered).
% "ztype" is 'symm' or 'asymm', passed as an argument to eiPlot_getZRange().
%
% "plotmeta" is a structure with the following fields:
%
%   "destchans" is a cell array with raw destination channel names.
%   "destcount" is the number of destination channels.
%   "destlabels" is a cell array with filename-safe destination labels.
%   "desttitles" is a cell array with plot-safe destination names.
%
%   "srcchans" is a cell array with raw source channel names.
%   "srccount" is the number of source channels.
%   "srclabels" is a cell array with filename-safe source labels.
%   "srctitles" is a cell array with plot-safe source names.
%
%   "pairmask" is a boolean matrix indexed by (dest, src, trial) that's true
%     for channel pairs that aren't self-comparisons, aren't permutations,
%     aren't squashed, and have desired sources and destinations.
%
%   "delaylist_ms" is a vector with information time lags.
%   "delaycount" is the number of information time lags.
%   "delaylabels" is a cell array with filename-safe time lag labels.
%   "delaytitles" is a cell array with plot-safe time lags.
%
%   "timelist_ms" is a vector with time window locations.
%   "timecount" is the number of time windows.
%   "timelabels" is a cell array with filename-safe time window locations.
%   "timetitles" is a cell array with plot-safe time window locations.
%
%   "trialnums" is a vector with trial numbers.
%   "trialcount" is the number of trials.
%   "triallabels" is a cell array with filename-safe trial numbers.
%   "trialtitles" is a cell array with plot-safe trial numbers.
%
%   "trialmask" is a boolean vector of the same size as "trialnums" that's
%     true for desired trials and false otherwise.
%
%   "timestep_ms" is the median time increment in "timelist_ms".
%
%   "zrange" is the range of pairwise information values in the data.


% Initialize.
plotmeta = struct();


%
% Get channel pair metadata.


destchans = infodata.destchans;
srcchans = infodata.srcchans;

plotmeta.destchans = destchans;
plotmeta.srcchans = srcchans;

plotmeta.destcount = length(destchans);
plotmeta.srccount = length(srcchans);

[ plotmeta.destlabels plotmeta.desttitles ] = ...
  euUtil_makeSafeStringArray( destchans );
[ plotmeta.srclabels plotmeta.srctitles ] = ...
  euUtil_makeSafeStringArray( srcchans );


% Consider each pair only once and mask self-comparisons.
pairmask = nlUtil_getPairMask( destchans, srcchans );

% Avoid plotting fully-squashed cases.
pairmask = pairmask & eiAux_getPairValidMask( infodata.(infofield) );

% Select only the requested channels.
pairmask = pairmask & ...
  eiAux_getDesiredPairMask( infodata, destswanted, srcswanted );

plotmeta.pairmask = pairmask;



%
% Get time and lag metadata.

delaylist_ms = infodata.delaylist_ms;
timelist_ms = infodata.windowlist_ms;

plotmeta.delaylist_ms = delaylist_ms;
plotmeta.timelist_ms = timelist_ms;

plotmeta.delaycount = length(delaylist_ms);
plotmeta.timecount = length(timelist_ms);

[ plotmeta.delaylabels plotmeta.delaytitles ] = ...
  nlUtil_makeIntegerTimeLabels( delaylist_ms, 'ms' );
[ plotmeta.timelabels plotmeta.timetitles ] = ...
  nlUtil_makeIntegerTimeLabels( timelist_ms, 'ms' );

% NOTE - Blithely assuming mostly-uniform spacing.
plotmeta.timestep_ms = median(diff(sort( timelist_ms )));



%
% Get trial number metadata.
% Handle the case where the data is aggregated across trials.

trialnums = infodata.trialnums;

if size(infodata.(infofield),3) < length(trialnums)
  % NOTE - Just give this a normal trial number.
  % Plotting functions should special-case single-trial vs many-trials.
  trialnums = 1;
end

plotmeta.trialnums = trialnums;
plotmeta.trialcount = length(trialnums);
plotmeta.triallabels = nlUtil_sprintfCellArray( 'tr%04d', trialnums );
plotmeta.trialtitles = nlUtil_sprintfCellArray( 'Tr %04d', trialnums );

% Build the trial mask.
trialmask = true(size(trialnums));
if ~isempty(trialswanted)
  % Output is the size of the first argument.
  trialmask = ismember(trialnums, trialswanted);
end

plotmeta.trialmask = trialmask;



%
% Get content metadata.

plotmeta.zrange = eiPlot_getZRange( infodata, infofield, ztype );



% Done.
end


%
% This is the end of the file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2018 Pentland Edge Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License"); you may not
%% use this file except in compliance with the License. 
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software 
%% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
%% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
%% License for the specific language governing permissions and limitations 
%% under the License.
%%
%% Some routines for generating sample Stanag 4607 packets.
-module(gen_4607).

-export([sample_mission_seg/0, sample_mission_seg/1]).

-export([sample_dwell_seg/2, sample_target_report/6]).

-export([tgt_report_list/1, positions_to_tgt_info/4]).

%% Lower level utilities.
-export([gen_position_fun/4, gen_position_list/6, timepoint_list/2]).

%% Constants to use with mission plan.
-define(MISSION_PLAN, "Hawk Sim 1").
-define(FLIGHT_PLAN, "FP 1").
-define(PLAT_CONFIG, "Sim v1.00").

%% Constants to use with target reports.
-define(SLANT_RANGE_UNC, 100). % c.m.
-define(CROSS_RANGE_UNC, 100). % d.m.
-define(HEIGHT_UNC, 10). % m.

%% @doc Generate a mission segment (including segment header) with today's 
%% date.
sample_mission_seg() ->
    {Date, _} = calendar:universal_time(),
    sample_mission_seg(Date).

%% @doc Generate a mission segment (including segment header) with the 
%% specified date.
sample_mission_seg({Year, Month, Day}) ->
    MS = mission:new(?MISSION_PLAN, 
                     ?FLIGHT_PLAN, 
                     other, 
                     ?PLAT_CONFIG, 
                     Year, 
                     Month, 
                     Day),
    segment:new(mission, MS).

%% @doc Generate a dwell segment with the specified list of target positions.
sample_dwell_seg(_DwellTimeMS, _Targets) ->
    ok.

%% @doc Generate a target report with the specified position.
sample_target_report(ReportIndex, Lat, Lon, Height, SNR, RCS) ->
    Params = [{mti_report_index, ReportIndex}, {target_hr_lat, Lat}, 
              {target_hr_lon, Lon}, {geodetic_height, Height},
              {target_snr, SNR}, {target_slant_range_unc, ?SLANT_RANGE_UNC}, 
              {target_cross_range_unc, ?CROSS_RANGE_UNC}, 
              {target_height_unc, ?HEIGHT_UNC}, {target_rcs, RCS}],
    
    % Extract the list of fields in the target report.
    FieldList = [K || {K, _V} <- Params],

    % Generate the target report and return it with the list of fields, 
    % present.
    {FieldList, tgt_report:new(Params)}.

%% @doc Generate a list of target reports.
tgt_report_list(TgtInfo) when is_list(TgtInfo) ->
    N = length(TgtInfo),
    Indices = lists:seq(0,N-1),
    F = fun(Index, {Lat, Lon, Height, SNR, RCS}) ->
            sample_target_report(Index, Lat, Lon, Height, SNR, RCS)
        end,
    TaggedReports = lists:zipwith(F, Indices, TgtInfo),
    TaggedReports.

%% @doc Generate a target information tuples from a list of target 
%% positions. Assumes constant height,RCS,SNR.
positions_to_tgt_info(Positions, Height, SNR, RCS) ->
    F = fun({Lat, Lon}) ->
            {Lat, Lon, Height, SNR, RCS}
        end,
    lists:map(F, Positions).

%% @doc Generate a function which can calcuate the position of a given target 
%% at a specified time. This is based on an initial position, a constant 
%% speed and bearing. The Haversine formula is used.
gen_position_fun(Lat, Lon, Bearing, Speed) ->
    fun(Time) ->
        Distance = Speed * Time,
        coord:destination({Lat, Lon}, Bearing, Distance)
    end.

%% @doc Generate a list of positions for an object moving at constant speed
%% and bearing.
gen_position_list(Lat, Lon, Bearing, Speed, N, TimeDelta) ->
    F = gen_position_fun(Lat, Lon, Bearing, Speed),
    TimeList = timepoint_list(N, TimeDelta),
    lists:map(F, TimeList).

%% @doc Generate a list of time points.
timepoint_list(N, TimeDelta) ->
    Points = lists:seq(0, N-1),
    lists:map(fun(P) -> TimeDelta * P end, Points).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2016 Pentland Edge Ltd.
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

-module(tgt_stats_tests).

-include_lib("eunit/include/eunit.hrl").

%% Define a test generator function to run all the tests. 
tgt_stats_test_() ->
    [datetime_string_checks(), extract_check1(), geojson_check1()].

datetime_string_checks() ->
    DT = {{2016,7,27},{8,12,59}},
    TimeStr = tgt_stats:datetime_to_string(DT),

    [?_assertEqual("2016-07-27 08:12:59", TimeStr)].

extract_check1() ->
    PacketList = packet_list:get_list1(),
    TgtStats = tgt_stats:extract(PacketList), 
    
    % Expect only a single dictionary to be returned.
    [DwellDict] = TgtStats,

    % Extract the mission time.
    MissTime = dict:fetch(mission_time, DwellDict),

    % Extract the dwell time.
    DwellTime = dict:fetch(dwell_time, DwellDict),

    % Convert to UTC (seconds precision).
    DwellUTC = tgt_stats:date_ms_to_datetime(MissTime, DwellTime),

    [?_assertEqual({2016, 7, 28}, MissTime),
     ?_assertEqual({{2016, 7, 28},{0, 16, 40}}, DwellUTC)].

geojson_check1() ->
    PacketList = packet_list:get_list1(),
    TgtStats = tgt_stats:extract(PacketList), 
    
    % Expect only a single dictionary to be returned.
    [DwellDict] = TgtStats,

    % Convert it to GeoJSON format.
    GJ = tgt_stats:dwell_to_geojson(DwellDict),

    % Extract the first part of the GeoJSON containing type.
    <<TypeStr:27/binary,Text2:52/binary,TimeStr:21/binary,_Rest/binary>> = GJ,

    % Next bit of the file should look like this.
    F2 = <<",\"features\":[{\"type\":\"Feature\",\"properties\":{\"time\":">>,

    % This is the hardcoded dwell time.
    DwellTime = <<"\"2014-09-10 09:42:26\"">>,

    [?_assertEqual(<<"{\"type\":\"FeatureCollection\"">>, TypeStr),
     ?_assertEqual(F2, Text2),
     ?_assertEqual(DwellTime, TimeStr)].


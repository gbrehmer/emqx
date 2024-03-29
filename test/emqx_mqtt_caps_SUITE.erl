%%--------------------------------------------------------------------
%% Copyright (c) 2019 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_mqtt_caps_SUITE).

-compile(export_all).
-compile(nowarn_export_all).

-include("emqx_mqtt.hrl").
-include_lib("eunit/include/eunit.hrl").

all() -> emqx_ct:all(?MODULE).

t_check_pub(_) ->
    PubCaps = #{max_qos_allowed => ?QOS_1,
                retain_available => false,
                max_topic_alias => 4
               },
    ok = emqx_zone:set_env(zone, '$mqtt_pub_caps', PubCaps),
    ok = emqx_mqtt_caps:check_pub(zone, #{qos => ?QOS_1,
                                          retain => false,
                                          topic_alias => 1
                                         }),
    PubFlags1 = #{qos => ?QOS_2, retain => false},
    ?assertEqual({error, ?RC_QOS_NOT_SUPPORTED},
                 emqx_mqtt_caps:check_pub(zone, PubFlags1)),
    PubFlags2 = #{qos => ?QOS_1, retain => true},
    ?assertEqual({error, ?RC_RETAIN_NOT_SUPPORTED},
                 emqx_mqtt_caps:check_pub(zone, PubFlags2)),
    PubFlags3 = #{qos => ?QOS_1, retain => false, topic_alias => 5},
    ?assertEqual({error, ?RC_TOPIC_ALIAS_INVALID},
                 emqx_mqtt_caps:check_pub(zone, PubFlags3)),
    true = emqx_zone:unset_env(zone, '$mqtt_pub_caps').

t_check_sub(_) ->
    SubOpts = #{rh  => 0,
                rap => 0,
                nl  => 0,
                qos => ?QOS_2
               },
    SubCaps = #{max_topic_levels => 2,
                max_qos_allowed => ?QOS_2,
                shared_subscription => false,
                wildcard_subscription => false
               },
    ok = emqx_zone:set_env(zone, '$mqtt_sub_caps', SubCaps),
    ok = emqx_mqtt_caps:check_sub(zone, <<"topic">>, SubOpts),
    ?assertEqual({error, ?RC_TOPIC_FILTER_INVALID},
                 emqx_mqtt_caps:check_sub(zone, <<"a/b/c/d">>, SubOpts)),
    ?assertEqual({error, ?RC_WILDCARD_SUBSCRIPTIONS_NOT_SUPPORTED},
                 emqx_mqtt_caps:check_sub(zone, <<"+/#">>, SubOpts)),
    ?assertEqual({error, ?RC_SHARED_SUBSCRIPTIONS_NOT_SUPPORTED},
                 emqx_mqtt_caps:check_sub(zone, <<"topic">>, SubOpts#{share => true})),
    true = emqx_zone:unset_env(zone, '$mqtt_sub_caps').

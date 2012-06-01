%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at http://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is Rabbitmq Loadbalanced Exchange.
%%
%% The Initial Developer of the Original Code is Tavisca Solution Pvt Ltd.
%% Copyright (c) 2011-2012 Tavisca Solution Pvt Ltd.  All rights reserved.
%%

-module(rabbit_exchange_type_loadbalanced_test).
-author("sujandutta@gmail.com").

-export([test/0]).
-include_lib("amqp_client/include/amqp_client.hrl").

test() ->
    Queues = [<<"lbTestQ1">>, <<"lbTestQ2">>],
    % default settings to localhost.
    {ok, Connection} = amqp_connection:start(#amqp_params_network{}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    #'exchange.declare_ok'{} = amqp_channel:call(Channel, #'exchange.declare'{
						   exchange = <<"lbTestX">>,
						   type = <<"x-loadbalanced">>,
						   auto_delete = false}),
    
    [#'queue.declare_ok'{} =
         amqp_channel:call(Channel, #'queue.declare' {queue = Q, exclusive = false }) || Q <- Queues],

    [#'queue.bind_ok'{} =
         amqp_channel:call(Channel, #'queue.bind' { queue = Q,
                                                 exchange = <<"lbTestX">>,
                                                 routing_key = <<"lb.test.rkey">> }) || Q <- Queues],
    Payload = <<"Testing LoadBalanced Exchange">>,
    Publish = #'basic.publish'{exchange = <<"lbTestX">>, routing_key = <<"lb.test.rkey">>},
    amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Payload}),
    
    Get = #'basic.get'{queue = <<"lbTestQ1">>, no_ack = true},
    case amqp_channel:call(Channel, Get) of
	{#'basic.get_ok'{}, Content} ->
	    #amqp_msg{payload = Payload} = Content;
	#'basic.get_empty'{} ->
	    Get2 = #'basic.get'{queue = <<"lbTestQ2">>, no_ack = true},
	    {#'basic.get_ok'{}, Content2} = amqp_channel:call(Channel, Get2),
	    #amqp_msg{payload = Payload} = Content2	    
    end,
    
    amqp_channel:close(Channel),
    amqp_connection:close(Connection),
    ok.

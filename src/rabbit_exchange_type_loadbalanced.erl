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

-module(rabbit_exchange_type_loadbalanced).
-author('sujandutta@gmail.com').

-include_lib("rabbit_common/include/rabbit.hrl").
-behaviour(rabbit_exchange_type).

-export([description/0, 
	 serialise_events/0, 
	 route/2]).

-export([validate/1, 
	 create/2, 
	 delete/3,
         add_binding/3, 
	 remove_bindings/3, 
	 assert_args_equivalence/2]).

-define(QMISSING, -99).

-rabbit_boot_step({?MODULE,
                   [{description, "exchange type loadbalanced: registry"},
                    {mfa,         {rabbit_registry, register,
                                   [exchange, <<"x-loadbalanced">>, ?MODULE]}},
                    {requires,    rabbit_registry},
                    {enables,     kernel_ready}]}).

description() ->
    [{name, <<"x-loadbalanced">>},
     {description, <<"an exchange, which routes to a queue depending upon number of messages present.">>}].

serialise_events() -> false.

route(#exchange{name = Name},#delivery{message = #basic_message{routing_keys = Routes}}) ->
    Matches = rabbit_router:match_routing_key(Name, Routes),
    case length(Matches) of
	Length when Length < 2 ->
	    Matches;
	_ ->
	    QMetadata = rabbit_amqqueue:lookup(Matches),
	    QStats = [{QName, QPid,  (fun(QPidIn) -> 
						   case rabbit_amqqueue:stat(#amqqueue{pid = QPidIn}) of
						      {ok, Count, _} ->
							  Count;
						      _ ->
							  ?QMISSING
				    		   end
				      end)(QPid)} 
		      || #amqqueue{name={_,_,queue,QName},pid=QPid} <- QMetadata, is_pid(QPid)],
	    FilterQueues = lists:filter(fun(QStat) ->
						{_,_, MsgCount} = QStat,
						MsgCount >= 0
					end, QStats), 
	    
	    [{QName, _, _}|_] = lists:keysort(3, FilterQueues),
	    case lists:keyfind(QName, 4, Matches) of
		false ->
		    [];
		FirstMatch ->
		    rabbit_log:info("Forwarded: ~p~n", [FirstMatch]),    
   		    [FirstMatch]
	    end
    end.

validate(_X) -> ok.
create(_Tx, _X) -> ok.
delete(_Tx, _X, _Bs) -> ok.
add_binding(_Tx, _X, _B) -> ok.
remove_bindings(_Tx, _X, _Bs) -> ok.
assert_args_equivalence(X, Args) ->
    rabbit_exchange:assert_args_equivalence(X, Args).

rabbitmq-loadbalanced-exchange
==============================

loadbalanced exchange("x-loadbalanced") is like direct exchange, which route the messages only to less loaded queue.

clone git repository to your "plugins-src" directory of rabbitmq codebase and from rabbitmq source codebase directory type the following command.

$make clean
$make

$scripts/rabbitmq-plugins list 

you should able to see the rabbitmq_loadbalanced_exchange in the listing.
and now enabled the same.

$scripts/rabbitmq-plugins enable rabbitmq_loadbalanced_exchange
$make run


now the plugin is enabled of type "x-loadbalanced" and you could create binding with multiple queues.



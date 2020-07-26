# Puppet Bolt Proxy

## Resume
We have modified the Bolt code so that it sends the commands that it wants to execute on the remote hosts first to a background process that saves the connections in a hash table. Every time there is a new request, it looks for if it has a connection to the remote host in its database. In case there is already one, it will reuse the connection to execute the action. Once the action has been executed on all remote hosts, it collects all the results and forwards them to the bolt client.

The background process can be executed on the local machine or on an external machine.

## Changes done
In the bolt client side we have had the file:
```
connector\_proxy.rb
```

And we have modify, the function run\_command in:

```
executor.rb
cli.rb
```

This way it sends the commands and the targets to the proxy. We have change cli.rb wo we can add use the flag --proxy

We have create a bolt\_demon, which has the sames files that bolt (probably lots of them are not necesaries) with also the following files:

```
bolt_demon.rb
connections_pool/base.rb
connections_pool/connections_pool.rb
proxy/connection.rb
proxy/connections.rb
proxy/proxy.rb
```

The bolt client sends the commands and the targets to the proxy thanks to executor.rb using connector\_proxy.rb
The bolt\_demon.rb rcv the option (now only comand option has been developped). If it rcv the option command, it calls the function process\_command from proxy/proxy.rb. This function rcv the commands and the targets, checks if there is connections avaible thanks to connections\_pool/connections\_pool.rb.
If there one connection avalaible then it resuse this for executing the command in the remote hosts.
If not it create a new one with proxy/connection.rb and stores it.

## Example of usage

```
bolt command run 'touch test1.txt' --proxy=playground-jdefruto-01:4913 --nodes playground-jdefruto-03
```

## Note

Right now we have two channel to connecto with the proxy. The first one to sends data bolt client to the proxy. It use the port you specific in the proxy flag. And the second one, is to transmit the results of running the command on the targets. We use now the port **4914**

The project is under developement

## More Info

[Technical report of the project](https://zenodo.org/record/1971291#.Xx4DWy1h1QI)



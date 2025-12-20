# Unikernel-regions
Project for building unikernels that uses region based memory management.

## Simple example
Below is a small example of a Unikernel service. The port `8080` is bound to a 
callback function which here is the identity function i.e. an echo service. It 
then listens for any incomming messages and sends back the payload for that 
message.
```ml
open Service

fun udpService handlerRequest = 
    case handlerRequest of
        (8080, payload) => payload 
    |   (_, _) => ""

structure TL = TransportLayerSingle(UdpHandler(val service = udpService))
structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end
```
The transport layer `UDP` can be swapped with a `TCP` implementation and here 
one has to choice between `STREAM` and `FULL`. In `STREAM` mode the service 
reply to each `TCP` segments as it receives them where in `FULL` mode the service
collects all segments before processing them. Below is an example where 
`8080` is set to `STREAM` and `8081` is set to `FULL`.
```ml
open Service

fun tcpService handlerRequest =
    case handlerRequest of
        (8080, SETUP) => SETUP_STREAM
    |   (8080, REQUEST payload) => REPLY payload
    |   (8081, SETUP) => SETUP_FULL
    |   (8081, REQUEST payload) => REPLY payload
    |   _ => IGNORE

structure TL = TransportLayerSingle(TcpHandler(val service = tcpService))

structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end
```

`UDP` and `TCP` can be combined using the `TransportLayerComb` *combinator* functor.
An example of `UDP` and `TCP` in unison is seen below:
```ml
open Service

fun tcpService handlerRequest =
    case handlerRequest of
        (8080, SETUP) => SETUP_STREAM
    |   (8080, REQUEST payload) => REPLY payload
    |   (8081, SETUP) => SETUP_FULL
    |   (8081, REQUEST payload) => REPLY payload
    |   _ => IGNORE

fun udpService handlerRequest = 
    case handlerRequest of
        (8082, payload) => payload 
    |   (_, _) => ""

structure TL = 
    TransportLayerComb(
        structure tl = TransportLayerSingle(TcpHandler(val service = tcpService))
        structure tlh = UdpHandler(val service = udpService))

structure Net = Network(IPv4Handle( structure FragAssembler = FragAssemblerList;
                                    structure TransportLayer = TL))

local
in
    val _ = Net.listen ()
end
```

### Further examples
The project include five small examples (these run on both Unix and [Unikraft](https://unikraft.org/)):
* `echo`: a simple echo server that mirrors exactly what it receives.
* `echoReverse`: reverses it's input and returns it.
* `facfib`: serves two ports with the factorial and fibonacci functions respectively.
* `monteCarlo`: estimates $\pi$ using the [sml-sobol library](https://github.com/diku-dk/sml-sobol) (run `smlpkg sync` before use).
* `sort`: sorts its given integers using mergesort.

## Logging
Logging can be turned on with the `Logging.enable` function and the service will 
print and log useful information depending on the specified protocol. For instance
logging `TCP` will result in:
```sh
-- TCP INFO --
Source port: 54346
Destination port: 8080
Sequence number: 3328429351
Acknowledgement number: 1
DOffset: 5
Reserved: 0
Control bits: 24
Flags: PSH | ACK
Window: 64240
Checksum: 63769
Urgent pointer: 0

Payload: Hello, world
```

Furthermore one has to specify a level of logging. Level 1 prints the header of 
the each segment and level 2 prints the header and the payload. An example of 
`TCP` with level 2 is seen below. 
```ml
val _ = Logging.enable {protocols=[Protocols.TCP], level = 2};
```

## Building and running for Unix
First, run the setup command to setup a tuntap device:
```sh
$ make setup
```

The `make` rule for compiling an app to unix:
```sh
$ make <application name>-ex-app
```

Run the application as an executable:
```sh
$ ./<application name>.exe
```

Once the unikernel is running one can send `UDP` packets to the unikernel via netcat:
```sh
$ echo -n $'Hello, World!\n' | nc -u -Nw1 10.0.0.2 8080
```

or `TCP` packets via netcat with:
```sh
$ echo -n $'Hello, World!\n' | nc -N 10.0.0.2 8080
```

## Building and running for Unikraft (through QEMU)
First, run the setup command to update and build external dependencies:
```sh
$ make t=uk setup
```

The `make` rule for compiling an app to Unikraft:
```sh
$ make t=uk <application name>-ex-app
```

Run the application with QEMU (this will set up a virtual bridge):
```sh
$ make run-uk
```

Once the unikernel is running one can send UDP packets to the unikernel via netcat:
```sh
$ echo -n $'Hello, World!\n' | nc -u -nw1 172.44.0.2 8080
```

## Creating your own application
To create an application create a new directory and include two files in the `examples` folder:
* `main.sml` which contains the code for the application
* `main.mlb` which is the ML basis file containing the applications dependencies

## Monitor network interface (tap0)
For montoring network traffic on unix:
```sh
$ sudo tshark -i tap0
```
Or unikraft:
```sh
$ sudo tshark -i virbr0
```

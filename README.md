# Unikernel-regions
Project for building unikernels that uses regions as the memory management 
method.

## Simple example
Here is a small example of a Unikernel service. The port `8080` is bound to a 
callback function which here is the identity function i.e. an echo service. It 
then listens for any incomming messages and sends back the payload for that 
message.
```ml
open Network

val _ = (
    listen [
            (UDP, [(8080, fn data => data)])
           ]
)
```

Logging can be turned on with the `Logging.enable` function and the service will 
print and log useful information depending on the specified protocol. For instance logging UDP will result in:
```sh
-- UDP INFO --
Source port: 50083
Destination port: 8080
UDP length: 14
Checksum: 30513
```

### Further examples
The project include four small examples (these run on both Unix and Xen - see below):
* Echo: a simple echo server that mirrors exactly what it receives.
* Facfib: serves two ports with the factorial and fibonacci functions respectively.
* MonteCarlo: estimates pi using the [sml-sobol library](https://github.com/diku-dk/sml-sobol) (run `smlpkg sync` before use).
* Sort: sorts its given integers using mergesort.

## Building and running for Unix
First run the setup command to setup a tuntap device:
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

Once the unikernel is running one can send UDP packets to the unikernel via netcat:
```sh
$ echo -n $'Hello, World!\n' | nc -u -nw1 10.0.0.2 8080
```

## Building and running for Unikraft (through QEMU)
First run the setup command to update and build external dependencies:
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
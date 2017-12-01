# Mesos cluster in one container
Standalone version of [mesos-in-docker](https://github.com/rwn3120/mesos-in-docker).

<script type="text/javascript" src="https://asciinema.org/a/jmaA105kP9jr58hsPmr4ZKX9C.js" id="asciicast-jmaA105kP9jr58hsPmr4ZKX9C" async></script>

## Try it!
Copy & paste these commands to your terminal
```
# sudo apt-get install -y jq    # run in case you don't have jq installed on your system
git clone git@github.com:rwn3120/mesos-in-docker-standalone.git
cd mesos-in-docker-standalone
./restart.sh
no_proxy=172.18.0.1 curl -sS 172.18.0.1:5050/system/stats.json | jq .
```
and then you can start to play around with
* [Mesos master](http://172.18.0.1:5050)
* [Marathon](http://172.18.0.1:8080/ui)
* [Metronome](http://172.18.0.1:9000)
* [Chronos](http://172.18.0.1:4400)
* [Apache Spark](http://172.18.0.1:8081)
## Usage
```
./start.sh                                  # start container

./stop.sh                                   # stop container

./restarh.sh                                # restart container

./build.sh mesos-standalone/Dockerfile      # re-build image
```

## Run Spark Application

```
# sudo apt-get install -y jq                # run in case you don't have jq installed on your system

./examples/spark_submit.sh                  # submit Spark application (calculates Pi)
```

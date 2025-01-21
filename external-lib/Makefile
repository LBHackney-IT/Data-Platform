.PHONY: all

all: target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar target/deequ-1.0.3.jar target/pydeequ-1.0.1.zip

target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar: pom.xml
	mvn package

target/deequ-1.0.3.jar:
	wget https://repo1.maven.org/maven2/com/amazon/deequ/deequ/1.0.3/deequ-1.0.3.jar -O target/deequ-1.0.3.jar

target/pydeequ-1.0.1.zip:
	pip3 install -t ./target pydeequ==1.0.1
	cd target && zip -r pydeequ-1.0.1.zip pydeequ

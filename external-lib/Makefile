.PHONY: all

all: target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar target/deequ-1.0.3.jar target/pydeequ-1.0.1.zip

target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar: pom.xml src/assembly/glue-jar-with-dependencies.xml
	mvn clean package
	@if jar tf $@ | grep -Eq '^(org/apache/logging/|org/slf4j/)'; then \
		echo "Glue runtime logging classes must not be bundled in $@"; \
		exit 1; \
	fi
	@if jar tf $@ | grep -qx 'scala/Predef.class'; then \
		echo "Glue runtime Scala classes must not be bundled in $@"; \
		exit 1; \
	fi

target/deequ-1.0.3.jar:
	wget https://repo1.maven.org/maven2/com/amazon/deequ/deequ/1.0.3/deequ-1.0.3.jar -O target/deequ-1.0.3.jar

target/pydeequ-1.0.1.zip:
	pip3 install -t ./target pydeequ==1.0.1
	cd target && zip -r pydeequ-1.0.1.zip pydeequ

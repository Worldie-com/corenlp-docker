FROM alpine:3.8 as builder
MAINTAINER Arne Neumann <nlpbox.programming@arne.cl>

RUN apk update && \
    apk add git wget openjdk8-jre-base py2-pip py2-curl && \
    pip install setuptools

# install latest CoreNLP release
WORKDIR /opt
RUN wget nlp.stanford.edu/software/stanford-corenlp-4.2.0.zip && \
    unzip stanford-corenlp-4.2.0.zip && \
    mv stanford-corenlp-4.2.0 corenlp && rm *.zip

# install latest English language model
#
# Docker can't store the result of a RUN command in an ENV, so we'll have
# to use this workaround.
# This command get's the first model file (at least for English there are two)
# and extracts its property file.
WORKDIR /opt/corenlp
RUN wget http://nlp.stanford.edu/software/stanford-corenlp-4.2.0-models-english.jar


# only keep the things we need to run and test CoreNLP
FROM alpine:3.8

RUN apk update && apk add openjdk8-jre-base py3-pip && \
    pip3 install pytest pexpect requests

WORKDIR /opt/corenlp
COPY --from=builder /opt/corenlp .

ADD test_api.py .

ENV JAVA_XMX 4g
EXPOSE 9000

CMD java -Xmx$JAVA_XMX -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -port 9000 -timeout 15000

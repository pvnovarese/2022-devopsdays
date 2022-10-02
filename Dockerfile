FROM alpine:latest

LABEL name="2022-devopsdays-lab0"

# there are a few other jars in the jar directory, change this to get 
# a variety of versions to search for later
#
COPY jars/log4j-core-2.14.1.jar  /

# just install a bunch of random stuff in the image to create
# a more interesting SBOM
#
RUN set -ex && \
    apk add --no-cache curl jq sudo ruby python3 && \
    gem install bundler lockbox:0.6.8 ftpd:0.2.1 && \
    python3 -m ensurepip && \
    pip3 install anchorecli && \
    pip3 install --index-url https://pypi.org/simple --no-cache-dir pytest urllib3 botocore six && \
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin  && \
    curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin 

HEALTHCHECK --timeout=10s CMD /bin/true || exit 1

## just to make sure we have a unique build each time 
RUN date > /image_build_timestamp_$(date +%Y-%m-%d_%T) && \
    
USER nobody
ENTRYPOINT /bin/false

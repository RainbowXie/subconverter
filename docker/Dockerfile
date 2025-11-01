# syntax=docker/dockerfile:1

FROM mirror.gcr.io/library/alpine:3.22 AS build-base
# ENV RUNNER_THREADS="4"
RUN apk update && \
    apk add --no-cache \
        coreutils grep sed && \
    apk add --no-cache --virtual .build-tools \
        build-base linux-headers pkgconf \
        cmake samurai \
        mold musl musl-dev musl-libintl musl-utils && \
    apk add --no-cache --virtual .build-deps \
        curl-dev curl-static \
        pcre2-dev pcre2-static \
        rapidjson-dev toml11 yaml-cpp-dev && \
    rm -rf /var/cache/apk/*

FROM build-base AS quickjspp
COPY --link --from=src_quickjspp / /quickjspp/
WORKDIR /quickjspp/
RUN cmake -DCMAKE_BUILD_TYPE=Release . && \
    mold -run make quickjs -j 2 && \
    install -m644 -pvD -t /emptydir/usr/lib/quickjs/ \
        quickjs/libquickjs.a && \
    install -m644 -pvD -t /emptydir/usr/include/quickjs/ \
        quickjs/quickjs.h quickjs/quickjs-libc.h && \
    install -m644 -pvD -t /emptydir/usr/include/ \
        quickjspp.hpp

FROM build-base AS libcron
COPY --link --from=src_libcron / /libcron/
WORKDIR /libcron/
RUN cmake -DCMAKE_BUILD_TYPE=Release . && \
    mold -run make libcron -j 2 && \
    install -m644 -pvD -t /emptydir/usr/lib/ \
        libcron/out/Release/liblibcron.a && \
    install -m644 -pvD -t /emptydir/usr/include/libcron/ \
        libcron/include/libcron/* && \
    install -m644 -pvD -t /emptydir/usr/include/date/ \
        libcron/externals/date/include/date/*

FROM build-base AS subconverter-builder
COPY --link --from=quickjspp /emptydir/ /
COPY --link --from=libcron   /emptydir/ /
COPY --link --from=src_subconverter   / /subconverter/
WORKDIR /subconverter/
RUN rm -f include/quickjspp.hpp && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    mold -run make -j 4

ARG CACHE_BUST
RUN echo "Cache bust: ${CACHE_BUST}" > /cache_bust.txt; \
    readelf -p .comment /subconverter/subconverter; \
    timeout 3s /subconverter/subconverter; \
    smoke_test=$? && \
    if [[ "${smoke_test}" -eq 0 ]] || [[ "${smoke_test}" -eq 124 ]]; then \
        echo "Smoke test passed"; \
    else \
        echo "Smoke test failed"; \
        exit 1; \
    fi


FROM mirror.gcr.io/library/alpine:3.22 AS final
LABEL maintainer="IceCodeNew"
RUN apk update && \
    apk add --no-cache \
        ca-certificates catatonit tzdata && \
    apk add --no-cache --virtual subconverter-deps \
        libcurl pcre2 yaml-cpp && \
    rm -rf /var/cache/apk/*

COPY --link --from=subconverter-builder --chmod=755 \
    /subconverter/subconverter /usr/bin/
COPY --link --from=src_subconverter \
    ./base/ /base/
WORKDIR /base/
ENTRYPOINT [ "catatonit", "--", "subconverter" ]
EXPOSE 25500/tcp

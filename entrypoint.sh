#!/bin/bash

AUTH_FLAG=""
if [ -n "$TTYD_USERNAME" ] && [ -n "$TTYD_PASSWORD" ]; then
    AUTH_FLAG="-c ${TTYD_USERNAME}:${TTYD_PASSWORD}"
fi

exec ttyd --writable --port 7681 $AUTH_FLAG bash

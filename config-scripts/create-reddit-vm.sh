#!/bin/bash
gcloud beta compute \
    --project=titanium-deck-253210 instances create reddit-full3 \
    --zone=europe-west1-b \
    --machine-type=g1-small \
    --subnet=default \
    --tags=puma-server \
    --image=reddit-full-1569410691 \
    --image-project=titanium-deck-253210 \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --boot-disk-device-name=reddit-full

#!/usr/bin/env bash
set -e

sudo systemctl restart displaylink.service 2>/dev/null \
  || sudo systemctl restart displaylink-driver.service

sleep 1
hyprctl reload

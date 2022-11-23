#!/usr/bin/env bash

set -Eeuo pipefail

bundle install
bundle exec rake spec

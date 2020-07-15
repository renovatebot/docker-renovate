#!/usr/bin/env node
import 'source-map-support/register'
import { logger } from 'renovate/dist/logger';

if (process.argv[1] !== '/usr/local/bin/renovate-config-validator') {
  logger.warn("Deprecated! Please use global 'renovate-config-validator' command.");
}

import 'renovate/dist/config-validator';

#!/usr/bin/env node
import 'source-map-support/register';
import { logger } from 'renovate/dist/logger';

if (process.argv[1] !== '/usr/local/bin/renovate') {
  logger.warn("Deprecated! Please use global 'renovate' command.");
}

import 'renovate/dist/renovate';

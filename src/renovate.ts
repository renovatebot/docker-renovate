#!/usr/bin/env node
import {logger} from 'renovate/dist/logger';
logger.warn('Deprecated! Please use global \'renovate\' command.')

import 'renovate/dist/renovate';

import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { getDatabaseConfig } from './database.config';

export default new DataSource(getDatabaseConfig() as any);

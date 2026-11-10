import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from './app.module';

const express = require('express');
import * as path from 'path';
import * as fs from 'fs';
import { registerWebRoutes } from './web-routes';

let server: any = null;
let isInitialized = false;

export async function createNestServer(expressInstance: any) {
  // Register public web pages (landing page, privacy policy, terms, account deletion)
  registerWebRoutes(expressInstance);

  const app = await NestFactory.create(AppModule, new ExpressAdapter(expressInstance));

  app.use(express.json({ limit: '25mb' }));
  app.use(express.urlencoded({ limit: '25mb', extended: true }));

  const prefix = process.env.API_PREFIX || 'api/v1';
  app.setGlobalPrefix(prefix);

  const uploadsDir = path.join(process.cwd(), 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    try {
      fs.mkdirSync(uploadsDir, { recursive: true });
    } catch {
      // safe ignore in serverless read-only filesystem
    }
  }
  app.use('/uploads', express.static(uploadsDir));
  app.use(`/${prefix}/uploads`, express.static(uploadsDir));

  const allowedOrigins = (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  app.enableCors({
    origin: allowedOrigins.length > 0 ? allowedOrigins : true,
    credentials: true,
  });
  app.use((_req: any, res: any, next: () => void) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    next();
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('SLOT Platform Backend API')
    .setDescription('Production API documentation for SLOT Salon Booking Platform')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  if (process.env.SWAGGER_ENABLED === 'true') {
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup(`${prefix}/docs`, app, document);
  }

  app.enableShutdownHooks();
  await app.init();
  return app;
}

// Standalone execution for local development
if (!process.env.VERCEL) {
  server = express();
  createNestServer(server).then(async (app) => {
    const port = parseInt(process.env.PORT || '3000', 10);
    const prefix = process.env.API_PREFIX || 'api/v1';
    await app.listen(port);
    const logger = new Logger('Bootstrap');
    logger.log(`🚀 SLOT Backend Server running on http://localhost:${port}/${prefix}`);
    logger.log(`📚 Swagger API Docs available on http://localhost:${port}/${prefix}/docs`);
  });
}

// Vercel Serverless Function entry point
export default async function handler(req: any, res: any) {
  if (!isInitialized) {
    try {
      server = express();
      await createNestServer(server);
      isInitialized = true;
    } catch (err: any) {
      console.error('[NestServer Initialization Error]', err);
      return res.status(503).json({
        statusCode: 503,
        status: 'database_configuration_required',
        message: 'SLOT Backend is live on Vercel, but waiting for PostgreSQL database credentials.',
        detail: err?.message || 'Database connection refused',
        instructions: 'Please connect a free Neon PostgreSQL database via Vercel Dashboard -> Storage -> Postgres, or add DATABASE_URL in Vercel Project Settings -> Environment Variables.',
        timestamp: new Date().toISOString(),
      });
    }
  }
  return server(req, res);
}


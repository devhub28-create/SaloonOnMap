import { Controller, Get, HttpException, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DataSource } from 'typeorm';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(private readonly dataSource: DataSource) {}

  @Get()
  @ApiOperation({ summary: 'General health check' })
  checkRoot() {
    return {
      status: 'ok',
      service: 'slot-backend',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('live')
  @ApiOperation({ summary: 'Liveness check verifying API process running' })
  checkLiveness() {
    return {
      status: 'up',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness check verifying PostgreSQL connectivity' })
  async checkReadiness() {
    try {
      if (!this.dataSource.isInitialized) throw new Error('uninitialized');
      await this.dataSource.query('SELECT 1');
    } catch {
      throw new HttpException(
        {
          status: 'down',
          timestamp: new Date().toISOString(),
          reason: 'Database connection unavailable',
        },
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }

    return {
      status: 'ready',
      timestamp: new Date().toISOString(),
      dependencies: {
        database: 'healthy',
      },
    };
  }
}

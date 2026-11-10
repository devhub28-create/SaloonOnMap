import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Version')
@Controller('version')
export class VersionController {
  @Get()
  @ApiOperation({ summary: 'Get immutable release version metadata' })
  getVersion() {
    return {
      version: process.env.RELEASE_VERSION || '1.0.0',
      commit: process.env.GIT_COMMIT_SHA || 'dev-build',
      environment: process.env.NODE_ENV || 'production',
      buildTime: process.env.BUILD_TIMESTAMP || new Date().toISOString(),
    };
  }
}

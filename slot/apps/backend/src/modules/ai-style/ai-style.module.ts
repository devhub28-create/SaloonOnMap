import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiStyleJob } from '../../entities/ai-style-job.entity';
import { AiSavedLook } from '../../entities/ai-saved-look.entity';
import { AiStyleService } from './ai-style.service';
import { AiStyleController } from './ai-style.controller';

@Module({
  imports: [TypeOrmModule.forFeature([AiStyleJob, AiSavedLook])],
  controllers: [AiStyleController],
  providers: [AiStyleService],
  exports: [AiStyleService],
})
export class AiStyleModule {}
